module Rails3JQueryAutocomplete
  module TestCase

    include Shoulda::InstanceMethods
    extend Shoulda::ClassMethods
    include Shoulda::Assertions
    extend Shoulda::Macros
    include Shoulda::Helpers

    context "the autocomplete gem" do

      should "be able to access the autocomplete action regardless of the quality of param[:term]" do
        get :autocomplete_movie_name
        assert_response :success

        get :autocomplete_movie_name, :term => ''
        assert_response :success

        get :autocomplete_movie_name, :term => nil
        assert_response :success

        get :autocomplete_movie_name, :term => 'Al'
        assert_response :success
      end

      should "respond with expected json" do
        get :autocomplete_movie_name, :term => 'Al'
        json_response = JSON.parse(@response.body)
        assert_equal(json_response.first["label"], @movie1.name)
        assert_equal(json_response.first["value"], @movie1.name)
        assert_equal(json_response.first["id"].to_s, @movie1.id.to_s)
      end

      should "return results in alphabetical order by default" do
        get :autocomplete_movie_name, :term => 'Al'
        json_response = JSON.parse(@response.body)
        assert_equal(json_response.first["label"], "Alpha")
        assert_equal(json_response.last["label"], "Alzpha")
      end

      should "be able to sort in other ways if desired" do
        @controller.class_eval do
          autocomplete :movie, :name, {:order => "name DESC"}
        end

        get :autocomplete_movie_name, :term => 'Al'
        json_response = JSON.parse(@response.body)
        assert_equal(json_response.first["label"], "Alzpha")
        assert_equal(json_response.last["label"], "Alpha")
      end

      should "be able to limit the results" do
        @controller.class_eval do
          autocomplete :movie, :name, {:limit => 1}
        end

        get :autocomplete_movie_name, :term => 'Al'
        json_response = JSON.parse(@response.body)
        assert_equal(json_response.length, 1)
      end

      should "be able to filter the results" do
        @controller.class_eval do
          autocomplete :movie, :name, {:filter_params => [:movie_type, :year]}
        end

        get :autocomplete_movie_name, :term => 'Al', :movie_type => "Porn", :year => "1942"
        json_response = JSON.parse(@response.body)
        assert_equal(1, json_response.length)
        assert_equal("Alzpha", json_response.first["label"])
      end

      should "not filter the results when key is not in request params" do
        @controller.class_eval do
          autocomplete :movie, :name, {:filter_params => [:movie_type]}
        end

        get :autocomplete_movie_name, :term => 'Al'
        json_response = JSON.parse(@response.body)
        assert_equal(3, json_response.length)
        assert_equal(json_response.first["label"], @movie1.name)
        assert_equal(json_response.first["value"], @movie1.name)
        assert_equal(json_response.first["id"].to_s, @movie1.id.to_s)
        assert_equal(json_response.last["label"], @movie3.name)
        assert_equal(json_response.last["value"], @movie3.name)
        assert_equal(json_response.last["id"].to_s, @movie3.id.to_s)
      end

      should "ignore case of search term and results" do
        @movie = @movie_class.create(:name => 'aLpHa')

        @controller.class_eval do
          autocomplete :movie, :name
        end

        get :autocomplete_movie_name, :term => 'Al'
        json_response = JSON.parse(@response.body)
        assert_equal(json_response.length, @movie_class.count)
        assert_equal(json_response.last["label"], 'aLpHa')
      end

      should "match term to letters in middle of words when full-text search is on" do
        @controller.class_eval do
          autocomplete :movie, :name, {:full => true}
        end

        get :autocomplete_movie_name, :term => 'ph'
        json_response = JSON.parse(@response.body)
        assert_equal(json_response.length, @movie_class.count)
        assert_equal(json_response.first["label"], @movie1.name)
      end

      should "be able to customize what is displayed" do
        @controller.class_eval do
          autocomplete :movie, :name, {:display_value => :display_name}
        end

        get :autocomplete_movie_name, :term => 'Al'

        json_response = JSON.parse(@response.body)

        assert_equal(@movie1.display_name, json_response.first["label"])
        assert_equal(@movie1.display_name, json_response.first["value"])
        assert_equal(@movie1.id.to_s, json_response.first["id"].to_s)
      end
    end
  end
end
