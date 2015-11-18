require 'rails_helper'

describe WorkflowPublisher do
  
  let(:thesis)  { Thesis.create }
  let(:dataset) { Dataset.create}
  let(:user)    { FactoryGirl.build(:user) }    
  
  describe '#perform_action' do
        
    context 'with thesis' do    
      
      let(:workflow_publisher) { WorkflowPublisher.new thesis }
      
      it 'should not call thesis#set_dataset_doi' do
        expect(thesis).to_not receive(:set_dataset_doi)
        workflow_publisher.perform_action(user)
      end
      
      it 'should not send email' do
        expect(workflow_publisher).to_not receive(:send_email)
        workflow_publisher.perform_action(user)
      end
      
      context 'in production mode' do
        
        before do
          allow(Rails).to receive(:env).and_return(
            OpenStruct.new(production?: true)
          )
        end
        
        it 'should send email' do
          expect(workflow_publisher).to receive(:send_email)
          workflow_publisher.perform_action(user)
        end
      end
      
      it 'should add to redis queue' do
        Resque.redis.flushdb
        allow(workflow_publisher).to receive(:ready_to_publish?).and_return(true)
        allow(workflow_publisher).to receive(:check_minimum_metadata).and_return([true, ['foo']])
        workflow_publisher.perform_action(user)
        data = JSON.parse(Resque.redis.rpop(Sufia.config.ora_publish_queue_name))
        expect(data['pid']).to eq(thesis.id.to_s)
      end
      
    end
    
    context 'with dataset' do
      
      let(:workflow_publisher) { WorkflowPublisher.new dataset }
      
      it 'should add to redis queue' do
        Resque.redis.flushdb
        allow(workflow_publisher).to receive(:ready_to_publish?).and_return(true)
        allow(workflow_publisher).to receive(:check_minimum_metadata).and_return([true, ['foo']])
        expect{
          workflow_publisher.perform_action(user)
        }.to change{Resque.keys.length}
      end
      
      it 'should not call dataset#set_dataset_doi' do
        expect(dataset).to_not receive(:set_dataset_doi)
        workflow_publisher.perform_action(user)
      end
      
      context 'having doi_requested and workflow not in user edit status' do
        
        before do
          allow(dataset).to receive(:doi_requested?).and_return(true)
          allow(dataset).to receive(:workflows).and_return(
            [
              OpenStruct.new(
                identifier: ['MediatedSubmission'],
                current_status: 'Foo'
              )
            ]
          )
        end
        
        it 'should call dataset#set_dataset_doi' do
          expect(dataset).to receive(:set_dataset_doi)
          workflow_publisher.perform_action(user)
        end
        
        
      end
      
    end
    
  end
  
end