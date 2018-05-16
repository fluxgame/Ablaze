Rails.application.routes.draw do
  resources :user_settings
  resources :asset_valuations
  get 'home/index'
  get 'home/net_worth'
  get 'home/mobile_sim'
  
  resources :future_account_balances
  resources :account_reconciliations
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
  resources :ledger_entries do
    member do
      get 'toggle_cleared'
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "home#index"
end
