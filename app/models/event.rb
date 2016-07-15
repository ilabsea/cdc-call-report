# == Schema Information
#
# Table name: events
#
#  id          :integer          not null, primary key
#  description :text(65535)
#  from_date   :date
#  to_date     :date
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Event < ActiveRecord::Base
	has_many :attachments, class_name: 'EventAttachment', dependent: :destroy

	validates :description, presence: true
	validates :attachments, presence: true

	validates :from_date,
  	date: { after_or_equal_to: Proc.new { Date.today }, message: 'must be after or equal to today' },
  	on: :create
	validates :to_date, date: { allow_blank: true, after_or_equal_to: :from_date, message: 'must be after or equal to from_date' }

	accepts_nested_attributes_for :attachments, allow_destroy: true, :reject_if => lambda { |e| e[:file].blank? }

	scope :past, -> { where("from_date < ?", Date.today) }

	UPCOMING = 'upcoming'
	PAST = 'past'

	ANNOUNEMENT_LISTING = 3
	
	def due_date
		if from_date === to_date or !to_date.present?
			from_date.to_s
		else
			from_date.to_s + " to " + to_date.to_s
		end
	end

	def self.upcoming days = nil
		return where("from_date >= ?", Date.today) if days.nil?
		where(from_date: Date.today...Date.today + days)
	end

	def over?
		return to_date < Date.today if to_date
		return from_date < Date.today
	end

end