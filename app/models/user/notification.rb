class User
  class Notification < ApplicationRecord
    belongs_to :user

    validates :read, inclusion: { in: [true, false] }
    validates :message, presence: true, length: { in: 1..128 }
    validates :link, presence: true, length: { in: 1..128 }

    scope :unread, -> { where(read: false) }
  end
end
