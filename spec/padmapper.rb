require_relative '../app.rb'

## to test the dynamically loaded modules we need to include them as well

Dir[File.dirname(__FILE__) + '/../mux/*.rb'].each {|file| load file }

describe Padmapper do
  before do
    @tokens = Padmapper.get_tokens
  end

  it 'responds to bundle' do
    expect(Padmapper.bundle.class).to eq(String)
  end

  it 'sets tokens' do
    expect(@tokens['x-csrftoken'].class).to eq(String)
  end

  it 'get listings' do

  end

  it 'makes post request' do
  end

  it 'responds with JSON' do
  end  

end
