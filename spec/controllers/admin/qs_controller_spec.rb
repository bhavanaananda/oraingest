require 'rails_helper'

RSpec.describe Admin::QsController, type: :controller do
  
  describe '#index' do
    
    it 'should render successfully' do
      get :index
      expect(response).to be_success
    end
    
    context 'no resque jobs' do
      
      it "@data['resque:ora_publish'] should be empty" do
        get :index
        expect(assigns(:data)['resque:ora_publish']).to eq([])
      end

    end
    
    context 'with rescue jobs present' do
      
      let(:uuid){'foo'}
      
      before do
        $redis.lpush 'resque:ora_publish', uuid # mock item in queue
      end
      
      after do
        $redis.lpop 'resque:ora_publish'
      end
      
      it "@data['resque:ora_publish'] should not be empty" do
        get :index
        expect(assigns(:data)['resque:ora_publish']).to eq([uuid])  
      end
      
    end
    
  end
  
end
