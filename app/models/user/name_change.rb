class User
  class NameChange < ApplicationRecord
    belongs_to :user, autosave: true
    belongs_to :approved_by, class_name: 'User', optional: true
    belongs_to :denied_by, class_name: 'User', optional: true

    validates :name, presence: true, length: { in: 1..64 }

    validate :unique_name, on: :create
    validate :only_one_request_per_user, on: :create
    validate :name_not_already_used, on: :create

    scope :pending, -> { where(approved_by: nil, denied_by: nil) }
    scope :approved, -> { where.not(approved_by: nil) }

    def pending?
      !approved_by && !denied_by
    end

    def approve(user, approved)
      if approved
        self.approved_by = user
        self.user.update!(name: name)
      else
        self.denied_by = user
      end
      save
    end

    private

    def unique_name
      if user.present? && name.present? && pending? && user.name == name
        errors.add(:name, 'must be different to the current name')
      end
    end

    def only_one_request_per_user
      if user.present? && pending? && !user.names.pending.empty?
        errors.add(:name, 'a name request is already pending')
      end
    end

    def name_not_already_used
      if name.present? && pending? && (User.where(name: name).exists? ||
                                       NameChange.pending.where(name: name).exists?)
        errors.add(:name, 'must be unique')
      end
    end
  end
end
