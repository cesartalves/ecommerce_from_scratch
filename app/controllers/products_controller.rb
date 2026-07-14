class ProductsController < ApplicationController
  def index
    @q = Product.ransack(params[:q])
    @products = @q.result.in_stock
  end

  def show
    @product = Product.find(params[:id])
  end
end
