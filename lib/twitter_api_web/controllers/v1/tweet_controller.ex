defmodule TwitterApiWeb.V1.TweetController do
  use TwitterApiWeb, :controller

  alias TwitterApi.Tweets
  alias TwitterApi.Tweets.Tweet
  alias TwitterApi.Accounts

  action_fallback TwitterApiWeb.FallbackController

  def index(conn, _params) do
    tweets = Tweets.list_tweets()
    render(conn, "index.json", tweets: tweets)
  end

  def create(conn, %{"tweet" => tweet_params}) do
    with {:ok, %Tweet{} = tweet} <- Tweets.create_tweet(conn.assigns.current_user, tweet_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.v1_tweet_path(conn, :show, [tweet]))
      |> render("show.json", tweet: tweet)
    end
  end

  def show(conn, %{"tweet_id" => id}) do
    tweet = Tweets.get_tweet!(id)
    render(conn, "show.json", tweet: tweet)
  end

  def delete(conn, %{"tweet_id" => id}) do
    tweet = Tweets.get_tweet!(id)

    with {:ok, %Tweet{}} <- Tweets.delete_tweet(tweet) do
      send_resp(conn, :no_content, "")
    end
  end

  def user_timeline(conn, %{"user_id" => id}) do
    user = Accounts.get_user!(id)

    tweets = Tweets.list_user_tweets(user)
    render(conn, "index.json", tweets: tweets)
  end

  def user_timeline(conn, %{"username" => username}) do
    user = Accounts.get_user_by_username!(username)

    tweets = Tweets.list_user_tweets(user)
    render(conn, "index.json", tweets: tweets)
  end

  def user_timeline(conn, _params) do
    if Map.has_key?(conn.assigns, :current_user) do
      tweets = Tweets.list_user_tweets(conn.assigns.current_user)
      render(conn, "index.json", tweets: tweets)
    else
      conn
      |> put_status(:unauthorized)
      |> put_view(TwitterApiWeb.ErrorView)
      |> render("401.json", message: "You must be signed in to access this endpoint.")
    end
  end

  def home_timeline(conn, _params) do
    tweets = Tweets.list_user_and_following_tweets(conn.assigns.current_user)
    render(conn, "index.json", tweets: tweets)
  end
end
