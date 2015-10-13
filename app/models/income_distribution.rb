class IncomeDistribution < ActiveRecord::Base
  include DateModule
  include IncomeDistributionsHelper
 
  validates_presence_of :distribution_date, :boa_chk, :chase_chk
  validates_numericality_of :boa_chk, :chase_chk
  validates_uniqueness_of :distribution_date

  validate :validate_date_is_friday

  RENT = 1550
  CAR_BASE_PAY_DAY = Date.new(2015,1,2)
  CAR_LOAN = 186.19

  CHASE_BASE_PAY_DAY = Date.new(2015,1,9)
  BOA_BUFFER = 10
  CHASE_BUFFER = 10

  def car_alloc
    bi_weekly_due(CAR_BASE_PAY_DAY,self.distribution_date) ? CAR_LOAN : 0
  end

  def rent_alloc
    (RENT*boa_fridays(self.distribution_date.at_beginning_of_month,self.distribution_date))/boa_fridays(self.distribution_date.at_beginning_of_month,self.distribution_date.at_end_of_month)
  end

  def boa_debts
    DebtBalance.joins(:debt).where("payment_start_date<='#{self.distribution_date}' AND due_date>='#{self.distribution_date}' AND debts.pay_from = 'Bank Of America'")
  end

  def chase_debts
    DebtBalance.joins(:debt).where("payment_start_date<='#{self.distribution_date}' AND due_date>='#{self.distribution_date}' AND debts.pay_from = 'Chase'")
  end

  def boa_debts_hash
    left_over = self.boa_focus
    left_over_total = self.boa_chk

    result = {}
    
    result["BoA"] = [self.boa_chk, BOA_BUFFER]
    left_over_total -= BOA_BUFFER
    
    boa_debts.map do |d|
      amount = d.debt.sub_category == "Car Loans" ? car_alloc : d.payment_due
      result[d.debt.name] = [amount, amount] #unless amount == 0
      left_over_total -= amount unless d.debt.name == left_over
    end

    result["Rent"] = [rent_alloc, rent_alloc]
    left_over_total -= rent_alloc

    result[left_over][1] = left_over_total unless result[left_over].nil?
    
    result
  end

  def chase_debts_hash
    left_over = self.chase_focus
    left_over_total = self.chase_chk
    result = {}
  
    result["Chase"] = [self.chase_chk, CHASE_BUFFER]
    left_over_total -= CHASE_BUFFER
 
    chase_debts.map do |d|
      amount =  bi_weekly_due(CHASE_BASE_PAY_DAY,self.distribution_date) ? d.payment_due : 0
      result[d.debt.name] = [amount, amount] #unless amount == 0
      left_over_total -= amount unless d.debt.name == left_over
    end

    result[left_over][1] = left_over_total unless result[left_over].nil?
    
    result
  end

  def debts_hash
      result = boa_debts_hash
      b = chase_debts_hash
      result = result.merge(b)
  end

  def boa_total_distribution
    total = 0
    boa_debts_hash.map{|k,v| total+=v[1].abs}
    total
  end

  def chase_total_distribution
    total = 0
    chase_debts_hash.map{|k,v| total+=v[1].abs}
    total
  end

  def total_chk
    self.chase_chk + self.boa_chk
  end

  def total_distribution
    boa_total_distribution + chase_total_distribution
  end

  def allocation(debt = nil)
    if debt
      debts_hash[debt] ? debts_hash[debt][1] : 0
    end
  end

  def allocations
    result = {}
    distro_list.map do |k,v| 
      if result[v[1]].nil?
        result[v[1]] = allocation(k)
      else
        result[v[1]] += allocation(k)
      end
    end
    result.sort
  end

  private
  def validate_date_is_friday
    errors.add(:distribution_date, "must be a Friday") unless self.distribution_date.wday == 5
  end

end
