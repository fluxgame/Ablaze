Rails.application.routes.draw do
  resources :user_settings
  resources :asset_valuations
  get 'home/index'
  get 'home/net_worth'
  get 'home/mobile_sim'
  
  resources :future_account_balances
  resources :account_reconciliations
  get '/transactions/scheduled', to: 'transactions#list_scheduled'
  resources :transactions do
    resources :ledger_entries
    collection do
      put :update_multiple
    end
  end
  resources :budget_goals
  devise_for :users
  resources :accounts do
    member do
      get 'reconcile'
      post 'transfer'
    end
  end
  resources :account_types
  resources :asset_types
  
  get '/ledger_entries/:id/toggle_cleared', to: 'ledger_entries#toggle_cleared', as: 'toggle_cleared_ledger_entry'
  
  # resources :ledger_entries do
  #   member do
  #     get 'toggle_cleared'
  #   end
  # end
  root to: "home#index"
end
