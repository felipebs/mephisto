require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < Test::Unit::TestCase
  fixtures :contents

  def test_sti_associations
    assert_equal contents(:welcome), contents(:welcome_comment).article
    assert_equal [contents(:welcome_comment)], contents(:welcome).comments
  end

  def test_should_add_comment_and_retrieve_site_id_from_article
    assert_difference Comment, :count do
      comment = contents(:welcome).comments.create :body => 'test comment', :author => 'bob', :author_ip => '127.0.0.1', :filter => 'textile_filter'
      assert_equal contents(:welcome).site_id, comment.site_id
    end
  end
  
  def test_should_pass_filter_down_from_article
    old_times = contents(:welcome).comments.collect &:updated_at
    comment = contents(:welcome).comments.create :body => 'test comment', :author => 'bob', :author_ip => '127.0.0.1', :filter => 'textile_filter'
    assert_equal 'textile_filter', comment.filter
    assert_valid comment
    assert_equal old_times, contents(:welcome).comments(true).collect(&:updated_at)
  end

  def test_should_process_textile_when_adding_comment
    c = contents(:welcome).comments.create :body => '*test* comment', :author => 'bob', :author_ip => '127.0.0.1'
    assert_equal "<p><strong>test</strong> comment</p>", c.body_html
  end

  def test_should_not_add_comment_to_pending_article
    assert_raises Article::CommentNotAllowed do
      contents(:future).comments.create(:body => 'flunk', :author => 'bob', :author_ip => '127.0.0.1')
    end
  end

  def test_should_not_add_comment_to_article_with_expired_comments
    assert_raises Article::CommentNotAllowed do
      contents(:about).comments.create(:body => 'flunk', :author => 'bob', :author_ip => '127.0.0.1')
    end
  end

  def test_should_increment_comment_count_upon_approval
    assert_difference contents(:welcome), :comments_count do
      contents(:unwelcome_comment).author = 'approved rico' # test method of setting approved comment
      assert contents(:unwelcome_comment).save
      assert contents(:unwelcome_comment).approved?
      contents(:welcome).reload
    end
  end
  
  def test_should_decrement_comment_count_upon_unapproval
    assert_difference contents(:welcome), :comments_count, -1 do
      contents(:welcome_comment).approved = false
      assert contents(:welcome_comment).save
      contents(:welcome).reload
    end
  end
  
  def test_should_not_decrement_unapproved_comment_count
    assert_no_difference contents(:welcome), :comments_count do
      contents(:unwelcome_comment).destroy
      contents(:welcome).reload
    end
  end
end
