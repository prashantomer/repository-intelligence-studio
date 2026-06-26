class SettingsController < ApplicationController
  def edit
    @user = current_user
    load_provider_status
  end

  def update
    @user = current_user

    if @user.update(settings_params)
      load_provider_status

      respond_to do |format|
        flash.now[:notice] = "AI assistant settings updated."
        format.turbo_stream
        format.html { redirect_to edit_settings_path, notice: "AI assistant settings updated." }
      end
    else
      load_provider_status

      respond_to do |format|
        format.turbo_stream { render :update, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def settings_params
    params.require(:user).permit(
      :name,
      :assistant_provider,
      :assistant_model,
      :embedding_provider,
      :embedding_model,
      :ollama_base_url
    )
  end

  def load_provider_status
    @assistant_profile = AiProviderProfile.profile_for(@user.assistant_provider)
    @embedding_profile = AiProviderProfile.profile_for(@user.embedding_provider)
  end
end
