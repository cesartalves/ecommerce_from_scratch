class AddressController < ApplicationController
  before_action :authenticate_user!

  def new
    @address = current_user.address || current_user.build_address
  end

  def create
    @address = current_user.build_address(address_params)

    if @address.save
      redirect_to root_path, notice: 'Endereço salvo com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def address_params
    params.require(:address).permit(
      :street,
      :number,
      :neighborhood,
      :city,
      :state,
      :zip_code
    )
  end
end
