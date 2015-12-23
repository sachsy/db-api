P_SCHEMA = File.read('../peeps/schema.sql')
P_FIXTURES = File.read('../peeps/fixtures.sql')
require '../test_tools.rb'

class TestTweets < Minitest::Test
	include JDB

	def test_add_tweet_wonka
		js = '{"id": 659144551454498816, "geo": null, "lang": "en", "text": "I am jumping on the @sivers “Now Page” bandwagon: https://t.co/clKe9GeQnm With a @simonsinek twist to it", "user": {"id": 16725749, "url": "http://t.co/737x6qTfDe", "lang": "en", "name": "Willy Wonka", "id_str": "16725749", "entities": {"url": {"urls": [{"url": "http://t.co/737x6qTfDe", "indices": [0, 22], "display_url": "wonka.com", "expanded_url": "http://wonka.com/"}]}, "description": {"urls": []}}, "location": "Indianapolis, IN", "verified": false, "following": false, "protected": false, "time_zone": "Eastern Time (US & Canada)", "created_at": "Mon Oct 13 19:22:22 +0000 2008", "utc_offset": -14400, "description": "Testing Willy Wonka", "geo_enabled": true, "screen_name": "wonka", "listed_count": 20, "friends_count": 308, "is_translator": false, "notifications": false, "statuses_count": 2184, "default_profile": false, "followers_count": 458, "favourites_count": 1015, "profile_image_url": "http://pbs.twimg.com/profile_images/461357535094534144/fqa7fyp7_normal.jpeg", "profile_banner_url": "https://pbs.twimg.com/profile_banners/16725749/1434601499", "profile_link_color": "2FC2EF", "profile_text_color": "666666", "follow_request_sent": false, "contributors_enabled": false, "has_extended_profile": true, "default_profile_image": false, "is_translation_enabled": false, "profile_background_tile": false, "profile_image_url_https": "https://pbs.twimg.com/profile_images/461357535094534144/fqa7fyp7_normal.jpeg", "profile_background_color": "000000", "profile_sidebar_fill_color": "252429", "profile_background_image_url": "http://pbs.twimg.com/profile_background_images/3440643/TwitterLogo2.gif", "profile_sidebar_border_color": "181A1E", "profile_use_background_image": true, "profile_background_image_url_https": "https://pbs.twimg.com/profile_background_images/3440643/TwitterLogo2.gif"}, "place": null, "id_str": "659144551454498816", "source": "<a href=\"https://about.twitter.com/products/tweetdeck\" rel=\"nofollow\">TweetDeck</a>", "entities": {"urls": [{"url": "https://t.co/clKe9GeQnm", "indices": [50, 73], "display_url": "wonka.com/now", "expanded_url": "http://wonka.com/now"}], "symbols": [], "hashtags": [], "user_mentions": [{"id": 2206131, "name": "Derek Sivers", "id_str": "2206131", "indices": [20, 27], "screen_name": "sivers"}, {"id": 15970050, "name": "Simon Sinek", "id_str": "15970050", "indices": [82, 93], "screen_name": "simonsinek"}]}, "favorited": false, "retweeted": false, "truncated": false, "created_at": "Tue Oct 27 23:08:02 +0000 2015", "coordinates": null, "contributors": null, "retweet_count": 0, "favorite_count": 3, "is_quote_status": false, "possibly_sensitive": false, "in_reply_to_user_id": null, "in_reply_to_status_id": null, "in_reply_to_screen_name": null, "in_reply_to_user_id_str": null, "in_reply_to_status_id_str": null}'
		qry('sivers.add_tweet($1)', [js])
		qry('sivers.get_tweet($1)', [@j[:id]])
		assert_equal 659144551454498816, @j[:id]
		assert_equal 'I am jumping on the @sivers “Now Page” bandwagon: http://wonka.com/now With a @simonsinek twist to it', @j[:message]
		assert_equal 'wonka', @j[:handle]
		assert_equal 2, @j[:person_id]
		assert @j[:created_at].start_with? '2015-10-2'
		assert_equal nil, @j[:seen]
		assert_equal nil, @j[:reference_id]
	end

	def test_add_tweet_dobalina
		js = '{"id": 659196999443591168, "geo": null, "lang": "en", "text": "H/T to @tomcritchlow and @sivers for inspiration on the /now page :) https://t.co/E5dYdzU8Zz", "user": {"id": 15140557, "url": "https://t.co/9Y72rhUoW7", "lang": "en", "name": "Bob Dobalina", "id_str": "15140557", "entities": {"url": {"urls": [{"url": "https://t.co/9Y72rhUoW7", "indices": [0, 23], "display_url": "dobalina.com", "expanded_url": "http://dobalina.com/"}]}, "description": {"urls": []}}, "location": "NYC ", "verified": false, "following": false, "protected": false, "time_zone": "Eastern Time (US & Canada)", "created_at": "Tue Jun 17 00:50:35 +0000 2008", "utc_offset": -14400, "description": "Bob Dobalina description here", "geo_enabled": true, "screen_name": "MistaDobalina", "listed_count": 70, "friends_count": 815, "is_translator": false, "notifications": false, "statuses_count": 4673, "default_profile": false, "followers_count": 602, "favourites_count": 3423, "profile_image_url": "http://pbs.twimg.com/profile_images/622871742831116289/zM7tTguR_normal.jpg", "profile_banner_url": "https://pbs.twimg.com/profile_banners/15140557/1408724422", "profile_link_color": "0A8080", "profile_text_color": "634047", "follow_request_sent": false, "contributors_enabled": false, "has_extended_profile": false, "default_profile_image": false, "is_translation_enabled": false, "profile_background_tile": false, "profile_image_url_https": "https://pbs.twimg.com/profile_images/622871742831116289/zM7tTguR_normal.jpg", "profile_background_color": "EDECE9", "profile_sidebar_fill_color": "E3E2DE", "profile_background_image_url": "http://abs.twimg.com/images/themes/theme3/bg.gif", "profile_sidebar_border_color": "D3D2CF", "profile_use_background_image": true, "profile_background_image_url_https": "https://abs.twimg.com/images/themes/theme3/bg.gif"}, "place": {"id": "01a9a39529b27f36", "url": "https://api.twitter.com/1.1/geo/id/01a9a39529b27f36.json", "name": "Manhattan", "country": "United States", "full_name": "Manhattan, NY", "attributes": {}, "place_type": "city", "bounding_box": {"type": "Polygon", "coordinates": [[[-74.026675, 40.683935], [-73.910408, 40.683935], [-73.910408, 40.877483], [-74.026675, 40.877483]]]}, "country_code": "US", "contained_within": []}, "id_str": "659196999443591168", "source": "<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>", "entities": {"urls": [{"url": "https://t.co/E5dYdzU8Zz", "indices": [70, 93], "display_url": "dobalina.com/now/", "expanded_url": "http://www.dobalina.com/now/"}], "symbols": [], "hashtags": [], "user_mentions": [{"id": 6419982, "name": "Tom Critchlow", "id_str": "6419982", "indices": [7, 20], "screen_name": "tomcritchlow"}, {"id": 2206131, "name": "Derek Sivers", "id_str": "2206131", "indices": [25, 32], "screen_name": "sivers"}]}, "favorited": false, "retweeted": false, "truncated": false, "created_at": "Wed Oct 28 02:36:26 +0000 2015", "coordinates": null, "contributors": null, "retweet_count": 0, "favorite_count": 1, "is_quote_status": false, "possibly_sensitive": false, "in_reply_to_user_id": 15140557, "in_reply_to_status_id": 659196273707327488, "in_reply_to_screen_name": "MistaDobalina", "in_reply_to_user_id_str": "15140557", "in_reply_to_status_id_str": "659196273707327488"}'
		qry('sivers.add_tweet($1)', [js])
		assert_equal 659196999443591168, @j[:id]
		qry('sivers.add_tweet($1)', [js])
		assert_equal 659196999443591168, @j[:id]
		qry('sivers.get_tweet($1)', [@j[:id]])
		assert_equal 'H/T to @tomcritchlow and @sivers for inspiration on the /now page :) http://www.dobalina.com/now/', @j[:message]
		assert_equal 'MistaDobalina', @j[:handle]
		assert_equal nil, @j[:person_id]
		assert @j[:created_at].start_with? '2015-10-2'
		assert_equal nil, @j[:seen]
		assert_equal 659196273707327488, @j[:reference_id]
	end
end

class TestComment < Minitest::Test
	include JDB

	def test_add
		qry("peeps.get_person(9)")
		assert_equal '404', @res[0]['status']
		qry("sivers.get_comment(6)")
		assert_equal '404', @res[0]['status']
		new_comment = {uri: 'boo',
			name: 'Bob Dobalina',
			email: 'bob@dobali.na',
			html: 'þ <script>alert("poop")</script> <a href="http://bad.cc">yuck</a> :-)'}
		qry("sivers.add_comment($1, $2, $3, $4)", [
			new_comment[:uri],
			new_comment[:name],
			new_comment[:email],
			new_comment[:html]])
		qry("peeps.get_person(9)")
		assert_equal 'Bob Dobalina', @j[:name]
		qry("sivers.get_comment(6)")
		assert_equal 9, @j[:person_id]
		assert_includes @j[:html], 'þ'
		refute_includes @j[:html], '<script>'
		assert_includes @j[:html], '&quot;poop&quot;'
		refute_includes @j[:html], '<a href'
		assert_includes @j[:html], 'yuck'
		assert_includes @j[:html], 'smile.gif'
	end
	
	def test_comments_newest
		qry("sivers.new_comments()")
		assert_equal [5, 4, 3, 2, 1], @j.map {|x| x[:id]}
	end

	def test_reply
		qry("sivers.reply_to_comment(1, 'Thanks')")
		assert_equal 'That is great.<br><span class="response">Thanks -- Derek</span>', @j[:html]
		qry("sivers.reply_to_comment(2, ':-)')")
		assert_includes @j[:html], 'smile'
		qry("sivers.reply_to_comment(999, 'Thanks')")
		assert_equal({}, @j)
	end

	def test_delete
		qry("sivers.delete_comment(5)")
		assert_equal 'spam2', @j[:html]
		qry("sivers.new_comments()")
		assert_equal [4, 3, 2, 1], @j.map {|x| x[:id]}
		qry("peeps.get_person(5)")
		assert_equal 'Oompa Loompa', @j[:name]
		qry("sivers.delete_comment(999)")
		assert_equal({}, @j)
	end

	def test_spam
		qry("sivers.spam_comment(5)")
		assert_equal 'spam2', @j[:html]
		qry("peeps.get_person(5)")
		assert_equal '404', @res[0]['status']
		qry("sivers.new_comments()")
		assert_equal [3, 2, 1], @j.map {|x| x[:id]}
		qry("sivers.spam_comment(999)")
		assert_equal({}, @j)
	end

	def test_update
		qry("sivers.update_comment(5, $1)", ['{"html":"new body", "name":"Opa!", "created_at":"2000-01-01"}'])
		assert_equal 'Opa!', @j[:name]
		assert_equal 'new body', @j[:html]
		assert_equal 'oompa@loompa.mm', @j[:email]
		assert_equal '2014-04-28', @j[:created_at]
		qry("sivers.update_comment(999, $1)", ['{"html":"hi"}'])
		assert_equal({}, @j)
	end

	def test_comment_person
		qry("sivers.get_comment(1)")
		assert_equal 'trust', @j[:uri]
		assert_equal 'Willy Wonka', @j[:person][:name]
		assert_equal 'musicthoughts', @j[:person][:stats][1][:name]
		assert_equal 'http://www.wonka.com/', @j[:person][:urls][0][:url]
		assert_equal 'you coming by?', @j[:person][:emails][0][:subject]
		qry("sivers.get_comment(999)")
		assert_equal({}, @j)
	end

	def test_comments_by_person
		qry("sivers.comments_by_person(2)")
		assert_equal [1], @j.map {|x| x[:id]}
		qry("sivers.comments_by_person(3)")
		assert_equal [2, 3], @j.map {|x| x[:id]}.sort
		qry("sivers.comments_by_person(5)")
		assert_equal [4, 5], @j.map {|x| x[:id]}.sort
	end

end
