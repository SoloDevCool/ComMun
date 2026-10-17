class AddUserSubmissionToQbQuestions < ActiveRecord::Migration[8.1]
  def change
    add_reference :qb_questions, :user, null: true, foreign_key: true, if_not_exists: true
    add_column :qb_questions, :status, :string, null: false, default: "approved", if_not_exists: true
    add_column :qb_questions, :rejection_reason, :text, if_not_exists: true
    add_column :qb_questions, :reviewed_at, :datetime, if_not_exists: true
    add_column :qb_questions, :reviewed_by, :integer, if_not_exists: true

    add_index :qb_questions, :status, if_not_exists: true
    add_index :qb_questions, :user_id, if_not_exists: true
  end
end
