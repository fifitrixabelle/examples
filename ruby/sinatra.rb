# frozen_string_literal: true

require 'sinatra'

get '/' do
  foo = params[:foo]
  return 'bar' unless foo

  'foo'
end
