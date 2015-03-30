require 'cudnn'
require 'modules/Reparametrize'
require 'modules/LinearCR'
require 'modules/SelectiveOutputClamp'
require 'modules/SelectiveGradientFilter'
require 'modules/PrintModule'


function build_atari_reconstruction_network(dim_hidden, feature_maps)
  -- Model-specific parameters
  input_image_width = 210
  input_image_height = 160
  filter_size = 5
  colorchannels = 3

  ----------- Encoder -------------------------
  encoder = nn.Sequential()

  encoder:add(cudnn.SpatialConvolution(colorchannels,feature_maps,filter_size,filter_size))
  encoder:add(cudnn.SpatialMaxPooling(2,2,2,2))
  encoder:add(nn.Threshold(0,1e-6))

  -- encoder:add(nn.PrintModule("after first convolution"))
  encoder:add(cudnn.SpatialConvolution(feature_maps,feature_maps/2,filter_size,filter_size))
  encoder:add(cudnn.SpatialMaxPooling(2,2,2,2))
  encoder:add(nn.Threshold(0,1e-6))

  -- encoder:add(nn.PrintModule("after second convolution"))
  encoder:add(cudnn.SpatialConvolution(feature_maps/2,feature_maps/4,filter_size,filter_size))
  encoder:add(cudnn.SpatialMaxPooling(2,2,2,2))
  encoder:add(nn.Threshold(0,1e-6))

  -- encoder:add(nn.PrintModule("before first reshape"))
  encoder:add(nn.Reshape((feature_maps/4) * (22) * (16) ))

  local z = nn.ConcatTable()

  local mu = nn.Sequential()
    mu:add(nn.LinearCR((feature_maps/4) * (22) * (16), dim_hidden))
    -- mu:add(nn.SelectiveGradientFilter())
    -- mu:add(nn.SelectiveOutputClamp())
  z:add(mu)

  local sigma = nn.Sequential()
    sigma:add(nn.LinearCR((feature_maps/4) * (22) * (16), dim_hidden))
    -- sigma:add(nn.SelectiveGradientFilter())
    -- sigma:add(nn.SelectiveOutputClamp())
  z:add(sigma)
  encoder:add(z)


  ----------- Decoder -------------------------
  decoder = nn.Sequential()
  decoder:add(nn.LinearCR(dim_hidden, (feature_maps/4) * (19) * (16) ))
  decoder:add(nn.Threshold(0,1e-6))
  -- decoder:add(nn.PrintModule("after LinearCR"))

  decoder:add(nn.Reshape((feature_maps/4), (19), (16) ))
  -- decoder:add(nn.PrintModule("after decoder reshape"))

  decoder:add(nn.SpatialUpSamplingNearest(2))
  decoder:add(cudnn.SpatialConvolution(feature_maps/4,feature_maps/2, 7, 7))
  decoder:add(nn.Threshold(0,1e-6))
  -- decoder:add(nn.PrintModule("after first decoder convolution"))

  decoder:add(nn.SpatialUpSamplingNearest(2))
  decoder:add(cudnn.SpatialConvolution(feature_maps/2,feature_maps, 8, 8))
  decoder:add(nn.Threshold(0,1e-6))
  -- decoder:add(nn.PrintModule("after second decoder convolution"))

  decoder:add(nn.SpatialUpSamplingNearest(2))
  decoder:add(cudnn.SpatialConvolution(feature_maps,feature_maps, 8, 7))
  decoder:add(nn.Threshold(0,1e-6))
  -- decoder:add(nn.PrintModule("after third decoder convolution"))

  decoder:add(nn.SpatialUpSamplingNearest(2))
  decoder:add(cudnn.SpatialConvolution(feature_maps,colorchannels, 7, 7))
  decoder:add(cudnn.Sigmoid())
  -- decoder:add(nn.PrintModule("after last decoder convolution"))


  ----------- Put it together -------------------------
  model = nn.Sequential()
  model:add(encoder)
  model:add(nn.Reparametrize(dim_hidden))
  model:add(decoder)

  model:cuda()
  collectgarbage()
  return model
end

function build_atari_prediction_network(dim_hidden, feature_maps, dim_prediction)
  -- Model-specific parameters
  local input_image_width = 210
  local input_image_height = 160
  local filter_size = 5
  local colorchannels = 3

  ----------- Encoder -------------------------
  encoder = nn.Sequential()

  encoder:add(cudnn.SpatialConvolution(colorchannels,feature_maps,filter_size,filter_size))
  encoder:add(cudnn.SpatialMaxPooling(2,2,2,2))
  encoder:add(nn.Threshold(0,1e-6))

  -- encoder:add(nn.PrintModule("after first convolution"))
  encoder:add(cudnn.SpatialConvolution(feature_maps,feature_maps/2,filter_size,filter_size))
  encoder:add(cudnn.SpatialMaxPooling(2,2,2,2))
  encoder:add(nn.Threshold(0,1e-6))

  -- encoder:add(nn.PrintModule("after second convolution"))
  encoder:add(cudnn.SpatialConvolution(feature_maps/2,feature_maps/4,filter_size,filter_size))
  encoder:add(cudnn.SpatialMaxPooling(2,2,2,2))
  encoder:add(nn.Threshold(0,1e-6))

  encoder:add(nn.Reshape((feature_maps/4) * (22) * (16) ))
  encoder:add(nn.PrintModule("after encoder"))

  predictor = nn.Sequential()
  predictor:add(nn.PrintModule("before JoinTable"))
  predictor:add(nn.JoinTable(2))
  predictor:add(nn.Linear((feature_maps/4) * (22) * (16) + 1, dim_prediction))
  predictor:add(nn.ReLU())
  predictor:add(nn.Linear(dim_prediction, dim_prediction))
  predictor:add(nn.ReLU())
  predictor:add(nn.Linear(dim_prediction, dim_prediction))
  predictor:add(nn.ReLU())

  local z = nn.ConcatTable()

  local mu = nn.Sequential()
    mu:add(nn.LinearCR(dim_prediction, dim_hidden))
    -- mu:add(nn.SelectiveGradientFilter())
    -- mu:add(nn.SelectiveOutputClamp())
  z:add(mu)

  local sigma = nn.Sequential()
    sigma:add(nn.LinearCR(dim_prediction, dim_hidden))
    -- sigma:add(nn.SelectiveGradientFilter())
    -- sigma:add(nn.SelectiveOutputClamp())
  z:add(sigma)
  predictor:add(z)


  ----------- Decoder -------------------------
  decoder = nn.Sequential()
  decoder:add(nn.LinearCR(dim_hidden, (feature_maps/4) * (19) * (16) ))
  decoder:add(nn.Threshold(0,1e-6))
  -- decoder:add(nn.PrintModule("after LinearCR"))

  decoder:add(nn.Reshape((feature_maps/4), (19), (16) ))
  decoder:add(nn.PrintModule("after decoder reshape"))

  decoder:add(nn.SpatialUpSamplingNearest(2))
  decoder:add(cudnn.SpatialConvolution(feature_maps/4,feature_maps/2, 7, 7))
  decoder:add(nn.Threshold(0,1e-6))
  -- decoder:add(nn.PrintModule("after first decoder convolution"))

  decoder:add(nn.SpatialUpSamplingNearest(2))
  decoder:add(cudnn.SpatialConvolution(feature_maps/2,feature_maps, 8, 8))
  decoder:add(nn.Threshold(0,1e-6))
  -- decoder:add(nn.PrintModule("after second decoder convolution"))

  decoder:add(nn.SpatialUpSamplingNearest(2))
  decoder:add(cudnn.SpatialConvolution(feature_maps,feature_maps, 8, 7))
  decoder:add(nn.Threshold(0,1e-6))
  -- decoder:add(nn.PrintModule("after third decoder convolution"))

  decoder:add(nn.SpatialUpSamplingNearest(2))
  decoder:add(cudnn.SpatialConvolution(feature_maps,colorchannels, 7, 7))
  decoder:add(cudnn.Sigmoid())
  decoder:add(nn.PrintModule("after last decoder convolution"))


  ----------- Put it together -------------------------
  model = nn.Sequential()
  -- model:add(nn.PrintModule("raw input"))

  z_in = nn.ParallelTable()
  z_in:add(encoder)
  -- z_in:add(nn.Identity())
  z_in:add(nn.PrintModule("input 2"))
  model:add(z_in)

  model:add(predictor)

  model:add(nn.Reparametrize(dim_hidden))
  model:add(decoder)

  model:cuda()
  print(model)
  collectgarbage()
  return model
end















