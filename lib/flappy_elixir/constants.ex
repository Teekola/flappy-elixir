defmodule Constants do
  @ground_y_position 140.0
  @gravity 0.1
  @jump_speed 1.5
  @ground_speed 0.65
  @pipe_speed 0.65
  @mountains_y_position 110.0
  @mountains_speed 0.025

  def get_ground_y_position do
    @ground_y_position
  end

  def get_gravity do
    @gravity
  end

  def get_jump_speed do
    @jump_speed
  end

  def get_ground_speed do
    @ground_speed
  end

  def get_pipe_speed do
    @pipe_speed
  end

  def get_mountains_y_position do
    @mountains_y_position
  end

  def get_mountains_speed do
    @mountains_speed
  end
end
