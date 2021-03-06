require 'spec_support'
require 'dep_definer_support'

def remove_constants_for str
  Babushka.send :remove_const, "#{str.camelize}DepDefiner"
  Babushka.send :remove_const, "#{str.camelize}DepRunner"
end

describe "name checks" do
  it "should not allow blank names" do
    L{ meta(nil) }.should raise_error ArgumentError, "You can't define a meta dep with a blank name."
    L{ meta('') }.should raise_error ArgumentError, "You can't define a meta dep with a blank name."
  end
  it "should not allow reserved names" do
    L{ meta(:base) }.should raise_error ArgumentError, "You can't use 'base' for a meta dep name, because it's reserved."
  end
  describe "duplicate declaration" do
    before { meta 'duplicate' }
    it "should be prevented" do
      L{ meta(:duplicate) }.should raise_error ArgumentError, "A meta dep called 'duplicate' has already been defined."
    end
    after { remove_constants_for 'duplicate' }
  end
end

describe "declaration" do
  before {
    @meta = meta 'test'
  }
  it "should set the name" do
    @meta.name.should == :test
  end
  it "should define a dep definer" do
    @meta.definer_class.should be_an_instance_of Class
    @meta.definer_class.ancestors.should include Babushka::BaseDepDefiner
  end
  it "should define a dep runner" do
    @meta.runner_class.should be_an_instance_of Class
    @meta.runner_class.ancestors.should include Babushka::BaseDepRunner
  end
  it "should define a dep helper" do
    Object.new.should_not respond_to 'helper_test'
    @meta = meta 'helper_test'
    Object.new.should respond_to 'helper_test'
  end

  describe "without template" do
    it "should define the helper" do
      Object.new.respond_to?('templateless_test').should be_false
      meta('templateless_test') {}
      Object.new.respond_to?('templateless_test').should be_true
    end
    describe "the helper" do
      before {
        meta('templateless_test') {}
      }
      it "should be callable" do
        templateless_test('templateless dep').should be_an_instance_of Dep
      end
    end
    after { remove_constants_for 'templateless_test' }
  end

  describe "with template" do
    before {
      @meta = meta 'template_test' do
        template {
          helper :a_helper do
            'hello from the helper!'
          end
          met? {
            'this dep is met.'
          }
        }
      end
    }
    it "should define the helper on the runner class" do
      @meta.runner_class.respond_to?(:a_helper).should be_false
      @meta.runner_class.new(nil).respond_to?(:a_helper).should be_false
      template_test('dep1').runner.respond_to?(:a_helper).should be_true
    end
    it "should correctly define the helper" do
      template_test('dep2').runner.a_helper.should == 'hello from the helper!'
    end
    it "should correctly define the met? block" do
      template_test('dep3').send(:call_task, :met?).should == 'this dep is met.'
    end
    it "should override the template correctly" do
      template_test('dep4') {
        met? { 'overridden met? block.' }
      }.send(:call_task, :met?).should == 'overridden met? block.'
    end
    after { remove_constants_for 'template_test' }
  end

  describe "acceptors" do
    before {
      @meta = meta 'acceptor_test' do
        accepts_list_for :list_test
        accepts_block_for :block_test
        template {
          met? {
            list_test == [ver('valid')]
          }
          meet {
            block_test.call
          }
        }
      end
    }
    it "should handle accepts_list_for" do
      acceptor_test('unmet accepts_list_for') { list_test 'invalid' }.met?.should be_false
      acceptor_test('met accepts_list_for') { list_test 'valid' }.met?.should be_true
    end
    it "should handle accepts_block_for" do
      block_called = false
      acceptor_test('accepts_block_for') {
        list_test 'invalid'
        block_test {
          block_called = true
        }
      }.meet
      block_called.should be_true
    end
    after { remove_constants_for 'acceptor_test' }
  end

  after { remove_constants_for 'test' }
end
