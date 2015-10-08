require 'rails_helper'

describe User do
  
  describe "abilities" do

    let(:user) { FactoryGirl.create(:user) }
    let(:article) { Article.new }
    
    context 'when user is not a reviewer' do 
      it 'user.can? :review should return false' do
        expect(user.can? :review, article).to eq(false)  
      end
    end
    
    context 'when user is a reviewer' do 
      
      before do
        user.stub(:reviewer?) {true}
      end
      
      it 'user.can? :review' do
        expect(user.can? :review, article).to eq(true)  
      end
    end 
    
  end
end

