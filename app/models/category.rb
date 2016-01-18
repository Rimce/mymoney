class Category < ActiveRecord::Base
  has_many :budgets
  has_many :spendings, through: :budgets
  has_many :debts

  belongs_to :user

  validates_presence_of :description, :name, :user_id
  validates_uniqueness_of :name, case_sensitive: false, scope: :user_id

  def to_s
    name
  end

  def owner
    user
  end
end
