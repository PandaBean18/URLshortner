class ShortenedUrl < ApplicationRecord
    validates :short_url, :long_url, presence: true 
    validate :no_spamming

    def self.random_code 
        random = false 
        while !random 
            code = SecureRandom.urlsafe_base64
            random = true if !(ShortenedUrl.exists?(short_url: code))
        end 
        return code 
    end 

    def self.create_shortened_url(user, long_url)
        code = ShortenedUrl.random_code
        ShortenedUrl.create!(long_url: long_url, short_url: code, user_id: user.id)
    end

    def self.prune(n)
        stale_urls = Visit.where('created_at < ?', n.minutes.ago).distinct
        stale_urls.each do |x|
            url = x.visited_url 
            url.url_visits.destroy_all
            url.taggings.delete_all
            url.destroy
        end 
    end
        

    def num_clicks
        url_id = self.id 
        return Visit.select(:user_id).where(shortened_url_id: url_id).count
    end

    def num_uniques
        url_id = self.id 
        return Visit.select(:user_id).where(shortened_url_id: url_id).distinct.count
    end

    def num_recent_clicks
        url_id = self.id 
        return Visit.select(:user_id).where({:shortened_url_id => url_id, :created_at => [10.minutes.ago..0.minutes.ago]}).distinct.count
    end

    belongs_to(:submitter, **{
        class_name: "User",
        foreign_key: "user_id",
        primary_key: "id"
    })

    has_many(:url_visits, **{
        class_name: "Visit",
        foreign_key: "shortened_url_id",
        primary_key: "id"
    })

    has_many(:visitors, Proc.new { distinct }, through: :url_visits, source: :url_visitor)

    has_many(:taggings, **{
        class_name: "Tagging",
        foreign_key: "url_id",
        primary_key: "id"
    })

    has_many(:tagged_topics, through: :taggings, source: :tagged_topic)

    private 

    def no_spamming
        if ShortenedUrl.where({user_id: self.user_id, created_at: [1.minutes.ago..Time.now]}).count >= 5
            errors[:spam] << "you can not submit more than 5 URLs in a minute"
        end 
    end

end