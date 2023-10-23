# frozen_string_literal: true

require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')
require 'active_record'
require 'globalize/model/active_record'

# Hook up model translation
ActiveRecord::Base.include Globalize::Model::ActiveRecord::Translated

# Load Post model
require_relative '../../data/models'

class PostgresArrayTest < ActiveSupport::TestCase
  test "works with simple dynamic finders" do
    array = Globalize::Model::ActiveRecord::PostgresArray.new('{abc,def}')
    assert_equal array[0], 'abc'
    assert_equal array[1], 'def'
  end

  test "converts NULL to nil" do
    string = '{abc,NULL,def}'
    array = Globalize::Model::ActiveRecord::PostgresArray.new(string)
    assert_equal array[0], 'abc'
    assert_nil array[1]
    assert_equal array[2], 'def'
    assert_equal array.pg_string, string
  end

  test "unescape strings with comma" do
    string = '{abc,"de,f"}'
    array = Globalize::Model::ActiveRecord::PostgresArray.new(string)
    assert_equal array[1], 'de,f'
    assert_equal array.pg_string, string
  end

  test "unescape strings space" do
    string = '{"Новое имя"}'
    array = Globalize::Model::ActiveRecord::PostgresArray.new(string)
    assert_equal array[0], "Новое имя"
    assert_equal array.pg_string, string
  end

  test "unescape strings with double quote" do
    string = '{abc,"de\\",f"}'
    array = Globalize::Model::ActiveRecord::PostgresArray.new(string)
    assert_equal array[1], 'de",f'
    assert_equal array.pg_string, string
  end

  test "double escape" do
    array = Globalize::Model::ActiveRecord::PostgresArray.new
    array[0] = 'Фирменная майка "Поставим продажи на рельсы"'
    assert_equal array.pg_string, '{"Фирменная майка \\"Поставим продажи на рельсы\\""}'
  end

  test "works with simple dynamic finders3" do
    string = '{abc,"de\\\\",fgh}'
    array = Globalize::Model::ActiveRecord::PostgresArray.new(string)
    assert_equal array[1], 'de\\'
    assert_equal array.pg_string, string
  end

  test "undestanding of string ','" do
    string = "{\",\"}"
    array = Globalize::Model::ActiveRecord::PostgresArray.new(string)
    assert_equal array[0], ','
    assert_equal array[1], nil
    assert_equal array.pg_string, string
  end

  test "integration" do
    string = '{"<h1 id=\\"h1title\\" class=\\"title\\">{{ collection.page_title }}</h1>
 {% if collection.description != nil %}
     <DIV id=\\"category-description\\" class=\\"textile\\">
       {{ collection.description }}
     </DIV>
 {% endif %}

 <DIV id=\\"products-header\\">
     <DIV id=\\"tag-filters\\">
            {% for property in collection.properties %}
           <DIV class=\\"property-line\\">
             <DIV class=\\"properties\\">
                 {{property.name}}
             </DIV>
             <DIV class=\\"separator\\">:</DIV>
             <DIV class=\\"characteristics\\">
             {% for characteristic in property.characteristics %}
                 {%if forloop.first == false %}, {%endif%}
                 {% if characteristic.current? %}
                      <b>{{characteristic.name}} ({{characteristic.products_count}})</b>
                 {% else %}
                     <a href=\'{{characteristic.url}}\'>{{characteristic.name}} ({{characteristic.products_count}})</a>
                 {% endif%}
             {% endfor %}
             </DIV>
           </DIV>
         {% endfor%}
      </DIV>
   <DIV id=\\"order-form-div\\">
     <form method=\\"get\\" id=\\"order_form\\">
         Сортировать по

         <select name=\\"order\\" onchange=\\"$(\'#order_form\').submit();\\">
           {{ \\"\\" | select_option: order, \\"\\" }}
           {{ \\"price\\"  | select_option: order, \\"Цене\\" }}
           {{ \\"title\\"  | select_option: order, \\"Названию\\" }}
         </select>
     </form>
     </DIV>
 </DIV>

 <div id=\\"page-content\\">
   <div class=\\"view-catalog\\">
   <div class=\\"tags\\" style=\\"display:none\\">{% for collection in current_collections %}{{ collection.title }}<br/>{% endfor %}</div>
     {% paginate products by 6 %}
     <TABLE id=\\"products-in-collection\\">
       {% tablerow product in products cols: 3 %}
         <div class=\\"node node-teaser\\">
           <div class=\\"node-inner\\" id=\\"product_{{ product.id }}\\">
             <div class=\\"img\\"><a href=\\"{{ product.url }}\\"><img src=\\"{{ product.first_image.thumb_url }}\\" alt=\\"[IMG]\\" title=\\"{{ product.title | escape }}\\" /></a></div>
             <h3 class=\\"title\\"><a href=\\"{{ product.url }}\\">{{ product.title | escape }}</a></h3>
             <div class=\\"content\\">
               <p class=\\"short-description\\">{{ product.short_description }}</p>
             </div>
           </div>
           <BR class=\'clear\'>
           <div class=\\"buyzone\\">
             <div class=\\"price\\">{{ product.sale_price | money }}</div>
             {% if product.variants.size == 1 %}
               <form action=\\"{{ cart.url }}\\" method=\\"post\\" id=\\"order\\">
                 <input type=\\"hidden\\" name=\\"product_id\\" value=\\"{{ product.id }}\\">
                 <input type=\\"hidden\\" name=\\"variant_id\\" value=\\"{{ product.variants[0].id }}\\">
                 <input type=\\"submit\\" class=\\"buy\\" value=\\"\\" title=\\"Купить\\" class=\\"add_product_to_cart\\"/>
                 <div class=\\"readmore\\"><a href=\\"{{ product.url }}\\">подробнее...</a></div>
               </form>
             {% else %}
               <a href=\\"{{ product.url }}\\" class=\\"buy\\" title=\\"Купить\\"></a>
               <div class=\\"readmore\\"><a href=\\"{{ product.url }}\\">подробнее...</a></div>
             {% endif %}
             <BR class=\'clear\'>
           </div>
           <BR class=\\"clear\\">
         </div>
       {% endtablerow %}
     </TABLE>
     <table class=\\"pager\\" border=\\"0\\"><tbody><tr><td>
     <ul>
       {% if paginate.previous %}
           <li>{{ \'&laquo;\' | link_to: paginate.previous.url}}</li>
       {% endif %}
       {% for part in paginate.parts %}

         {% if part.is_link %}
           <li>{{ part.title | link_to: part.url }}</li>
         {% else %}
           <li class=\\"active\\"><span>{{ part.title }}</span></li>
         {% endif %}

       {% endfor %}
       {% if paginate.next %}
       <li>{{ \'&raquo;\' | link_to: paginate.next.url }}</li>
       {% endif %}
     </ul>
     </td></tr></tbody></table>
     {% endpaginate %}
   </div>
   <div class=\\"clear\\"> </div>
 </div>

 "}'
    array = Globalize::Model::ActiveRecord::PostgresArray.new(string)
    assert_equal array.pg_string, string.gsub(/}/, '\}').gsub(/{/, '\{').sub(/\A\\/, '').gsub(/\\}\z/, '}')
  end
end
