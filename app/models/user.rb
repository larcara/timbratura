class User < ActiveRecord::Base
  has_many :clocks
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :timeoutable ,#:ldap_authenticatable, #:registerable,
         :recoverable, #:rememberable,
         :trackable#, :validatable

  validates :password, { confirmation: true, length: { in: 6..20 }, allow_blank: true, allow_nil:  true  }

  def is_admin?
    role=="admin"
  end
  def is_camera?
    return true if is_admin?
    role=="camera"
  end
end
