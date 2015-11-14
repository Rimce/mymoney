module BudgetsHelper
  include DateModule

  THRESHOLD="2015-10-01"

  def overall_budget(date = nil)
    Budget.joins(:category).where("categories.name NOT IN ('Credit Cards')").where(budget_month: date).sum(:amount) 
  end

  def student_loan_budget(date = nil)
    savings = DebtBalance.joins(:debt).where("payment_start_date<='#{date}' AND due_date>='#{date}' AND debts.sub_category = 'Student Loans'")
    result = 0
    if savings.exists?
      savings.each {|saving| result += saving.payment_due * (date >= Date.new(2015,10,1) ? paychecks(saving.debt.pay_from,date) : 0) }
    end
    result
  end

  def car_loan_budget(date = nil)
    start_date = date.nil? ? Date.new(1864,1,1) : date.change(day: 1)
    end_date = date.nil? ? Date.new(1864,1,1) : date.end_of_month
    date >= Date.new(2014,7,1) ? 186.19 * (boa_fridays(start_date,end_date)-chase_fridays(start_date,end_date)) : 0
  end
  
  def credit_payment_budget(date = nil)
    savings = DebtBalance.joins(:debt).where("payment_start_date<='#{date}' AND due_date>='#{date}' AND debts.sub_category = 'Credit Cards'")
    result = 0
    if savings.exists?
      savings.each {|saving| result += saving.payment_due * paychecks(saving.debt.pay_from,date)  }
    end
    result
  end

  def credit_payment_budget_notes(date = nil)
    savings = DebtBalance.joins(:debt).where("payment_start_date<='#{date}' AND due_date>='#{date}' AND debts.sub_category = 'Credit Cards'")
    result = "Estimated payments needed to payoff all credit card balances: "
    if savings.exists?
      savings.each {|saving| result += "#{saving.debt.name} => #{number_to_currency(saving.payment_due)} x #{paychecks(saving.debt.pay_from,date)}; "  }
    end
    result
  end

  def savings_budget(date = nil)
    savings = DebtBalance.joins(:debt).where("payment_start_date<='#{date}' AND due_date>='#{date}' AND debts.sub_category = 'Savings'")
    result = 0
    if savings.exists?
      savings.each {|saving| result += saving.payment_due(date) * paychecks(saving.debt.pay_from,date)  }
    end
    result
  end

  def loans_budget(date = nil)
    car_loan_budget(date)+student_loan_budget(date)
  end

  def fixed_budget(date = nil)
    result = 0
    result += Budget.joins(:category)
                   .where("categories.name NOT IN ('Credit Cards')")
                   .where("categories.name IN ('Rent','Utilities','Insurance','Phone/TV/Internet')")
                   .where(budget_month: date)
                   .sum(:amount)

    result += savings_budget(date)
    result += loans_budget(date)

    result
  end

  def fixed_budget_notes(date = nil)
    result = "Fixed budgets: "
    result += "Other => #{number_to_currency(Budget.joins(:category)
                   .where("categories.name NOT IN ('Credit Cards')")
                   .where("categories.name IN ('Rent','Utilities','Insurance','Phone/TV/Internet')")
                   .where(budget_month: date)
                   .sum(:amount))}; "

    result += "Savings => #{number_to_currency(savings_budget(date))}; "
    result += "Loans => #{number_to_currency(loans_budget(date))}; "

    result
  end

  def variable_budget(date = nil)
    overall_budget(date)-fixed_budget(date)
  end

  def credit_budget(date = nil)
    overall_budget(date) - debit_budget(date)
  end

  def debit_budget(date = nil)
    fixed_budget(date) - Budget.joins(:category)
                   .where("categories.name NOT IN ('Credit Cards')")
                   .where("categories.name IN ('Insurance','Phone/TV/Internet')")
                   .where(budget_month: date)
                   .sum(:amount)
  end

  def potential_income(curr_month = nil)
    if !curr_month.nil?
      start_date = curr_month.change(day: 1)
      end_date = curr_month.end_of_month
      if start_date < Date.new(2015,10,1)
        chase_fridays(start_date,end_date) * 1837.09 + nih_fridays(start_date,end_date) * 1137.31
      elsif start_date >= Date.new(2015,10,1) && start_date < Date.new(2015,11,1)
        chase_fridays(start_date,Date.new(2015,10,14)) * 1837.09 + nih_fridays(start_date,Date.new(2015,10,14)) * 1137.31 + nih_fridays(Date.new(2015,10,15),end_date) * 1085.31
      else
        chase_fridays(start_date,end_date) * 0 + nih_fridays(start_date,end_date) * 1085.31
      end
    end
  end

  def paychecks(pay_from = nil, date = nil)
     start_date = date.nil? ? Date.new(1864,1,1) : date.change(day: 1)
     end_date = date.nil? ? Date.new(1864,1,1) : date.end_of_month
     if date < Date.new(2015,10,1)
       if pay_from == "Chase"
         chase_fridays(start_date,end_date)
       else
         boa_fridays(start_date,end_date)
       end
     else 
        nih_fridays(start_date,end_date)
     end
  end
end
