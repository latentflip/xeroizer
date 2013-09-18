require "test_helper"

class BankTransactionTest < Test::Unit::TestCase
  include TestHelper
  include Xeroizer::Record

  def setup
    fake_parent = Class.new do
      attr_accessor :application
      def mark_dirty(*args); end
    end.new

    the_line_items = [
      LineItem.build({:quantity => 1, :tax_amount => 0.15, :unit_amount => 1.00, :tax_amount => 0.50}, nil),
      LineItem.build({:quantity => 1, :tax_amount => 0.15, :unit_amount => 1.00, :tax_amount => 0.50}, nil)
    ]

    @the_bank_transaction = BankTransaction.new fake_parent
    @the_bank_transaction.line_items = the_line_items

    @client = Xeroizer::PublicApplication.new(CONSUMER_KEY, CONSUMER_SECRET)
    mock_api('BankTransactions')
  end

  context "given a bank_transaction with line_amount_types set to \"Exclusive\"" do
    setup do
      @the_bank_transaction.line_amount_types = "Exclusive"
    end

    must "calculate the total as the sum of its line item line_amount and tax_amount" do
      assert_equal "3.0", @the_bank_transaction.total.to_s
    end

    must "calculate the sub_total as the sum of the line_amounts" do
      assert_equal "2.0", @the_bank_transaction.sub_total.to_s
    end
  end

  context "given a bank_transaction with line_amount_types set to \"Inclusive\"" do
    setup do
      @the_bank_transaction.line_amount_types = "Inclusive"
    end

    must "calculate the total as the sum of its line item line_amount and tax_amount" do
      assert_equal "2.0", @the_bank_transaction.total.to_s
    end

    must "calculate the sub_total as the sum of the line_amounts minus the total tax" do
      assert_equal "1.0", @the_bank_transaction.sub_total.to_s
    end
  end

  context "bank transaction totals" do
    should "large-scale testing from API XML" do
      bank_transactions = @client.BankTransaction.all
      bank_transactions.each do | bank_transaction |
        assert(!!bank_transaction.attributes[:currency_code], "Doesn't have currency code in attributes")
        assert(!!bank_transaction.currency_code, "Doesn't have currency code in model")
        assert(!!bank_transaction.currency_rate, "Doesn't have currency rate in model")


        assert_equal(bank_transaction.attributes[:currency_code], bank_transaction.currency_code)

        if bank_transaction.attributes[:currency_rate]
          assert_equal(bank_transaction.attributes[:currency_rate], bank_transaction.currency_rate)
        else
          assert_equal(1.0, bank_transaction.currency_rate)
        end
      end
    end

    should "handle bank transfers properly" do
      bank_transactions = @client.BankTransaction.all
      bank_transaction = bank_transactions.find { |bt| bt.attributes[:type] == "SPEND-TRANSFER" }

      assert( bank_transaction.is_transfer? )
      assert_equal( bank_transaction.attributes[:total], bank_transaction.total)
      assert_equal( bank_transaction.attributes[:total], bank_transaction.sub_total)
      assert_equal( 0, bank_transaction.total_tax)
    end

  end
end
