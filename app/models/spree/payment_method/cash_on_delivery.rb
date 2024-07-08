class Spree::PaymentMethod::CashOnDelivery < Spree::PaymentMethod
  preference :fee, :float

  def payment_profiles_supported?
    true # we want to show the confirm step.
  end

  def post_create(payment)
    return false if fee_exists?(payment)

    Spree::Adjustment.create!(
      amount: preferred_fee,
      order: payment.order,
      adjustable: payment.order,
      source: self,
      label:
    )
  end

  def update_adjustment(adjustment, _src)
    adjustment.update_attribute_without_callbacks(:amount, preferred_fee)
  end

  def authorize(*_args)
    ActiveMerchant::Billing::Response.new(true, '', {}, {})
  end

  def capture(_payment, _source, _gateway_options)
    ActiveMerchant::Billing::Response.new(true, '', {}, {})
  end

  def void(*_args)
    ActiveMerchant::Billing::Response.new(true, '', {}, {})
  end

  def actions
    %w[capture void]
  end

  # Indicates whether its possible to capture the payment
  def can_capture?(payment)
    %w[checkout pending].include?(payment.state)
  end

  def can_void?(payment)
    payment.state != 'void'
  end

  def source_required?
    false
  end

  # def provider_class
  #  self.class
  # end

  def payment_source_class
    nil
  end

  def method_type
    'cash_on_delivery'
  end

  def label
    I18n.t('cash_on_delivery.label')
  end

  private

  def fee_exists?(payment)
    payment.order.adjustments.where('label = ?', label).exists?
  end

  def public_preference_keys
    [:fee]
  end
end
