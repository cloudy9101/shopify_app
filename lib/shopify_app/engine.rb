# frozen_string_literal: true

module ShopifyApp
  module RedactJobParams
    private

    def args_info(job)
      log_disabled_classes = ["ShopifyApp::WebhooksManagerJob"]
      return "" if log_disabled_classes.include?(job.class.name)

      super
    end
  end

  class Engine < Rails::Engine
    engine_name "shopify_app"
    isolate_namespace ShopifyApp

    initializer "shopify_app.middleware" do |app|
      app.config.middleware.insert_after(::Rack::Runtime, ShopifyApp::JWTMiddleware)
    end

    initializer "shopify_app.assets" do |app|
      app.config.assets.paths << root.join('app', 'assets', 'javascripts', 'shopify_app').to_s
    end

    initializer "shopify_app.redact_job_params" do
      ActiveSupport.on_load(:active_job) do
        if ActiveJob::Base.respond_to?(:log_arguments?)
          WebhooksManagerJob.log_arguments = false
        elsif ActiveJob::Logging::LogSubscriber.private_method_defined?(:args_info)
          ActiveJob::Logging::LogSubscriber.prepend(RedactJobParams)
        end
      end
    end
  end
end
