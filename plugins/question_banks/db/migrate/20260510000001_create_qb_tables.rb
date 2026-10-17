class CreateQbTables < ActiveRecord::Migration[8.1]
  def change
    create_table :qb_exams do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :type_name, null: false
      t.string :color, default: "#6366f1"
      t.string :description
      t.integer :total_count, default: 0
      t.integer :duration, default: 150
      t.json :categories, default: []
      t.string :level, null: false, default: "junior"
      t.integer :sort_order, default: 0
      t.timestamps
    end
    add_index :qb_exams, :code, unique: true
    add_index :qb_exams, :level
    add_index :qb_exams, :sort_order

    create_table :qb_questions do |t|
      t.references :qb_exam, null: false, foreign_key: true
      t.integer :question_type, null: false, default: 0
      t.string :category
      t.text :content, null: false
      t.json :options, null: false, default: []
      t.integer :answer, null: false
      t.text :explanation
      t.integer :sort_order, default: 0
      t.timestamps
    end
    add_index :qb_questions, [:qb_exam_id, :sort_order]

    create_table :qb_practices do |t|
      t.references :user, null: false, foreign_key: true
      t.references :qb_exam, null: false, foreign_key: true
      t.string :mode, null: false
      t.integer :total_count, default: 0
      t.integer :correct_count, default: 0
      t.integer :wrong_count, default: 0
      t.integer :unanswered_count, default: 0
      t.integer :time_spent, default: 0
      t.boolean :completed, default: false
      t.timestamps
    end
    add_index :qb_practices, [:user_id, :qb_exam_id]
    add_index :qb_practices, :mode

    create_table :qb_answers do |t|
      t.references :qb_practice, null: false, foreign_key: true
      t.references :qb_question, null: false, foreign_key: true
      t.integer :selected_option
      t.boolean :is_correct
      t.timestamps
    end
    add_index :qb_answers, [:qb_practice_id, :qb_question_id], unique: true
  end
end
