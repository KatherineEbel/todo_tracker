require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require "pry"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

helpers do
  # return error message if list name invalid
  def error_for_list_name(name)
    if !(1..100).cover? name.size
       "List name must be between 1 and 100 characters."
    elsif session[:lists].any? { |list| list[:name] == name }
       "The list #{name} already exists."
    end
  end

  def error_for_todo(name)
    if !(1..100).cover? name.size
       "Todo must be between 1 and 100 characters."
    end
  end
end

get "/" do
  redirect "/lists"
end

# GET /lists    -> view all lists
# GET /lists/new  -> new list form
# POST /lists     -> create new list
# GET /lists/1    -> view a single list

# View list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name list_name
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list #{list_name} has been created."
    redirect "/lists"
  end
end

# /Display a list's todos
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

# Edit existing todo list
get "/lists/:id/edit" do
  @list = session[:lists][params[:id].to_i]
  @name = @list[:name]
  erb :edit_list, layout: :layout
end

# Update existing todo list
post "/lists/:id" do
  new_name = params[:list_name].strip
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  error = error_for_list_name new_name
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = new_name
    session[:success] = "The list has been successfully changed."
    redirect "/lists/#{@list_id}"
  end
end

# delete list
post "/lists/:id/delete" do
  @list_id = params[:id].to_i
  session[:success] = "#{session[:lists].delete_at(@list_id)[:name]} has been deleted."
  redirect "/lists"
end

# add new todo
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: text, completed: false }
    session[:success] = "The todo was added to your list."
    redirect "/lists/#{@list_id}"
  end
end

#delete a todo from list
post "/lists/:list_id/todos/:id/delete" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:id].to_i
  session[:success] = "#{@list[:todos].delete_at(todo_id)[:name] } has been deleted"
  redirect "/lists/#{@list_id}"
end

# uptdate todo status
post "/lists/:list_id/todos/:id/" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "#{@list[:todos][todo_id][:name]} has been successfully updated."
  redirect "/lists/#{@list_id}"
end
