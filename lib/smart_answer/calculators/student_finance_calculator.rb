module SmartAnswer
  module Calculators
    class StudentFinanceCalculator
      attr_accessor(
        :course_start,
        :household_income,
        :residence,
        :course_type,
        :part_time_credits,
        :full_time_credits,
        :dental_or_medical_course,
        :doctor_or_dentist,
      )

      LOAN_MAXIMUMS = {
        "2017-2018" => {
          "at-home" => 7_097,
          "away-outside-london" => 8_430,
          "away-in-london" => 11_002
        },
        "2018-2019" => {
          "at-home" => 7_324,
          "away-outside-london" => 8_700,
          "away-in-london" => 11_354
        }
      }.freeze
      REDUCED_MAINTENTANCE_LOAN_AMOUNTS = {
        "at-home" => 1744,
        "away-in-london" => 3263,
        "away-outside-london" => 2324
      }
      CHILD_CARE_GRANTS = {
        "2017-2018" => {
          "one-child" => 159.59,
          "more-than-one-child" => 273.60
        },
        "2018-2019" => {
          "one-child" => 164.70,
          "more-than-one-child" => 282.36
        },
      }
      PARENTS_LEARNING_ALLOWANCE = {
        "2017-2018" => 1_617,
        "2018-2019" => 1_669,
      }
      ADULT_DEPENDANT_ALLOWANCE = {
        "2017-2018" => 2_834,
        "2018-2019" => 2_925,
      }
      TUITION_FEE_MAXIMUM = {
        "full-time" => 9_250,
        "part-time" => 6_935,
      }
      LOAN_MINIMUMS = {
        "2017-2018" => {
          "at-home" => 3_124,
          "away-outside-london" => 3_928,
          "away-in-london" => 5_479
        },
        "2018-2019" => {
          "at-home" => 3_224,
          "away-outside-london" => 4_054,
          "away-in-london" => 5_654
        },
      }.freeze
      INCOME_PENALTY_RATIO = {
        "2017-2018" => {
          "at-home" => 8.36,
          "away-outside-london" => 8.26,
          "away-in-london" => 8.12
        },
        "2018-2019" => {
          "at-home" => 8.10,
          "away-outside-london" => 8.01,
          "away-in-london" => 7.87
        },
      }.freeze

      def initialize(params = {})
        @course_start = params[:course_start]
        @household_income = params[:household_income]
        @residence = params[:residence]
        @course_type = params[:course_type]
        @part_time_credits = params[:part_time_credits]
        @full_time_credits = params[:full_time_credits]
        @dental_or_medical_course = params[:dental_or_medical_course]
        @doctor_or_dentist = params[:doctor_or_dentist]
      end

      def reduced_maintenance_loan_for_healthcare
        REDUCED_MAINTENTANCE_LOAN_AMOUNTS[@residence]
      end

      def childcare_grant_one_child
        CHILD_CARE_GRANTS.fetch(@course_start).fetch("one-child")
      end

      def childcare_grant_more_than_one_child
        CHILD_CARE_GRANTS.fetch(@course_start).fetch("more-than-one-child")
      end

      def parent_learning_allowance
        PARENTS_LEARNING_ALLOWANCE.fetch(@course_start)
      end

      def adult_dependant_allowance
        ADULT_DEPENDANT_ALLOWANCE.fetch(@course_start)
      end

      def tuition_fee_maximum
        if @course_type == "uk-full-time" || @course_type == "eu-full-time"
          tuition_fee_maximum_full_time
        else
          tuition_fee_maximum_part_time
        end
      end

      def tuition_fee_maximum_full_time
        TUITION_FEE_MAXIMUM.fetch("full-time")
      end

      def tuition_fee_maximum_part_time
        TUITION_FEE_MAXIMUM.fetch("part-time")
      end

      def doctor_or_dentist?
        (@course_start == '2017-2018' && @dental_or_medical_course == "doctor-or-dentist") ||
          (@course_start == '2018-2019' && @doctor_or_dentist)
      end

      def maintenance_grant_amount
        SmartAnswer::Money.new(0)
      end

      def maintenance_loan_amount
        return SmartAnswer::Money.new(0) if @course_start == '2017-2018' && @course_type == "uk-part-time"

        reduced_amount = max_loan_amount - reduction_based_on_income
        SmartAnswer::Money.new([reduced_amount, min_loan_amount].max * loan_proportion)
      end

      def course_start_years
        year_matches = /(\d{4})-(\d{4})/.match(@course_start)
        [year_matches[1].to_i, year_matches[2].to_i]
      end

    private

      def max_loan_amount
        LOAN_MAXIMUMS[@course_start][@residence]
      end

      def min_loan_amount
        LOAN_MINIMUMS[@course_start][@residence]
      end

      def reduction_based_on_income
        return 0 if @household_income <= 25_000

        ratio = INCOME_PENALTY_RATIO[@course_start][@residence]
        ((@household_income - 25_000) / ratio).floor
      end

      def course_intensity
        100 * (part_time_credits.to_f / full_time_credits)
      end

      def loan_proportion
        return 1 if @course_type == "uk-full-time" || course_intensity == 100
        return 0.75 if course_intensity >= 75
        return 0.666 if course_intensity >= 66.6
        return 0.5 if course_intensity >= 50
        return 0.333 if course_intensity >= 33.3
        return 0.25 if course_intensity >= 25
        0
      end
    end
  end
end
