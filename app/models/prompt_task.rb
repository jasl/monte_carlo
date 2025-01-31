# frozen_string_literal: true

class PromptTask < ApplicationRecord
  belongs_to :meta_prompt, optional: true
  belongs_to :user

  enum :status, {
    # drafting: "drafting",
    pending: "pending",
    submitting: "submitting",
    submitted: "submitted",
    processing: "processing",
    processed: "processed",
    discarded: "discarded",
    errored: "errored"
  }

  enum :result, {
    success: "success",
    fail: "fail",
    error: "error",
    panic: "panic"
  }

  validates :prompt,
            presence: true,
            allow_blank: false

  validates :sd_model_name,
            presence: true,
            inclusion: {
              in: Constants::SUPPORTED_SD_MODEL_NAMES,
              message: "%{value} isn't supported anymore."
            },
            allow_blank: false

  validates :sampler_name,
            presence: true,
            inclusion: {
              in: Constants::SUPPORTED_SAMPLER_NAMES,
              message: "%{value} isn't supported anymore."
            },
            allow_blank: false

  validates :width,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: Constants::WIDTH_RANGE.begin,
              less_than_or_equal_to: Constants::WIDTH_RANGE.end
            },
            allow_blank: false

  validates :height,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: Constants::HEIGHT_RANGE.begin,
              less_than_or_equal_to: Constants::HEIGHT_RANGE.end
            },
            allow_blank: false

  validates :seed,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: Constants::RANDOM_SEED_RANGE.begin,
              less_than_or_equal_to: Constants::RANDOM_SEED_RANGE.end
            },
            allow_blank: false

  validates :steps,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: Constants::STEP_RANGE.begin,
              less_than_or_equal_to: Constants::STEP_RANGE.end
            },
            allow_blank: false

  validates :cfg_scale,
            presence: true,
            numericality: {
              only_integer: false,
              greater_than_or_equal_to: Constants::CFG_SCALE_RANGE.begin,
              less_than_or_equal_to: Constants::CFG_SCALE_RANGE.end,
            },
            allow_blank: false

  validates :clip_skip,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: Constants::CLIP_SKIP_RANGE.begin,
              less_than_or_equal_to: Constants::CLIP_SKIP_RANGE.end,
            },
            allow_blank: false

  validates :hires_fix_upscaler_name,
            presence: true,
            inclusion: {
              in: Constants::SUPPORTED_HIRES_UPSCALER_NAMES,
              message: "%{value} isn't supported."
            },
            allow_blank: false,
            if: :hires_fix?

  validates :hires_fix_upscale,
            presence: true,
            numericality: {
              only_integer: false,
              greater_than_or_equal_to: Constants::HIRES_FIX_UPSCALE_RANGE.begin,
              less_than_or_equal_to: Constants::HIRES_FIX_UPSCALE_RANGE.end
            },
            allow_blank: false,
            if: :hires_fix?

  validates :hires_fix_steps,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: Constants::HIRES_FIX_STEPS_RANGE.begin,
              less_than_or_equal_to: Constants::HIRES_FIX_STEPS_RANGE.end
            },
            allow_blank: false,
            if: :hires_fix?

  validates :hires_fix_denoising,
            presence: true,
            numericality: {
              only_integer: false,
              greater_than_or_equal_to: Constants::HIRES_FIX_DENOISING_RANGE.begin,
              less_than_or_equal_to: Constants::HIRES_FIX_DENOISING_RANGE.end
            },
            allow_blank: false,
            if: :hires_fix?

  validates :status,
            presence: true,
            inclusion: {
              in: self.statuses.values
            }

  validates :result,
            inclusion: {
              in: self.results.values
            },
            allow_blank: true

  after_initialize do |record|
    next unless record.new_record?

    record.status ||= :pending
  end

  def submit!
    return false unless pending?

    self.unique_track_id = "0x#{SecureRandom.hex(16)}"
    self.status = :submitting
    self.submitting_at = Time.zone.now
    save!

    SubmitPromptTaskJob.perform_later(id)
  end
end
