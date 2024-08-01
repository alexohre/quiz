# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_07_10_221839) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "quizzes", force: :cascade do |t|
    t.text "question"
    t.string "answer"
    t.boolean "answered", default: false
    t.bigint "stage_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "question_number"
    t.index ["answer"], name: "index_quizzes_on_answer"
    t.index ["question"], name: "index_quizzes_on_question"
    t.index ["question_number"], name: "index_quizzes_on_question_number"
    t.index ["stage_id"], name: "index_quizzes_on_stage_id"
  end

  create_table "stages", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active"
  end

  add_foreign_key "quizzes", "stages"
end
