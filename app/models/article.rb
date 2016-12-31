class Article < ApplicationRecord
  include Post

  belongs_to :theme

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :categorizations, dependent: :destroy
  has_many :categories, through: :categorizations
  has_many :contributions, dependent: :destroy
  has_many :articles, foreign_key: :parent_id
  belongs_to :collection, foreign_key: :parent_id, class_name: :Article

  accepts_nested_attributes_for :contributions, reject_if: :all_blank, allow_destroy: true

  scope :chronological, -> { order(published_at: :desc) }

  scope :root, -> { where(parent_id: nil) }

  before_validation :generate_slug,            on: [:create, :update]
  before_validation :generate_published_dates, on: [:create, :update]
  before_validation :downcase_content_format,  on: [:create, :update]

  default_scope { order("published_at DESC") }
  scope :live,        -> { where("published_at < ?", Time.now) }
  scope :on, lambda { |date| where("published_at BETWEEN ? AND ?", date.try(:beginning_of_day), date.try(:end_of_day)) }

  def path
    if published?
      published_at.strftime("/%Y/%m/%d/#{slug}")
    else
      "/drafts/articles/#{self.draft_code}"
    end
  end

 # Overwrites slug_exists? from Slug.  We allow duplicate slugs on different
 # published_at dates.
  def slug_exists?
    Article.on(published_at).where(slug: slug).exists?
  end

  def save_tags!(tags_glob)
    self.taggings.destroy_all

    tags_glob.split(",").each do |name|
      unless name.blank?
        tag = Tag.find_or_create_by(name: name.strip)
        self.tags << tag
      end
    end
  end

  def save_categories!(categories_glob)
    self.categorizations.destroy_all

    categories_glob.split(",").each do |name|
      unless name.blank?
        category = Category.find_or_create_by(name: name.strip)
        self.categories << category
      end
    end
  end

  # article states through the process from creation to publishing
  def draft?
    status.name == "draft"
  end

  def edited?
    status.name == "edited"
  end

  def designed?
    status.name == "designed"
  end

  def published?
    status.name == "published"
  end

  def dated?
    published_at.present?
  end

  def collection_root?
    articles.any?
  end

  def in_collection?
    collection.present?
  end

  private

  def generate_published_dates
    if published_at.present?
      self.year  = published_at.year                     if published_at.year.present?
      self.month = published_at.month.to_s.rjust(2, "0") if published_at.month.present?
      self.day   = published_at.day.to_s.rjust(2, "0")   if published_at.day.present?
    end
  end

  def downcase_content_format
    self.content_format = self.content_format.downcase
  end
end
