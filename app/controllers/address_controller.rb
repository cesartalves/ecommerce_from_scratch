class AddressController < ApplicationController
  before_action :authenticate_user!

  def new
    @address = current_user.address || current_user.build_address
  end

  def create
    @address = current_user.address || current_user.build_address

    if @address.update(address_params)
      redirect_to checkout_path, notice: "Endereço salvo com sucesso."
    else
      flash[:alert] = "Erro ao salvar o endereço."
      render :new
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
      :zipcode
    )
  end
end