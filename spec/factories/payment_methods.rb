require 'faker'

FactoryGirl.define do
  factory :payment_method do
    name { Faker::Commerce.product_name }
    description { Faker::Commerce.department(5) }
    user

    factory :payment_method_with_spendings do
      transient do
        spendings_count 2
      end

      after(:create) do |payment_method, evaluator|
        create_list(:spending, evaluator.spendings_count, payment_method: payment_method)
      end
    end
  end
end
