FactoryGirl.define do
  
  factory :user, :class => User do |u|
    sequence(:email){|n| "foo.bar#{n}@example.com" }
    password 'password'
  end
  
  factory :work_flow_user, :class => User do |u|
    email 'jilluser@example.com'
    password 'password'
  end

  factory :archivist, :class => User do |u|
    email 'archivist1@example.com'
    password 'password'
  end

  factory :reviewer, class: User do |u|
    email 'archivist1@example.com'
    password 'password'
  end
  
  factory :curator, :class => User do |u|
    email 'curator1@example.com'
    password 'password'
  end
end