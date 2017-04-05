--[[
    Zeiler FRCNN model.
]]

require 'nn'
require 'cudnn'
require 'inn'


local function CreateModel(opt, utils)
  
    assert(opt)
    assert(utils)
    
    -- load features + model parameters (mean/std,stride/num feats (last conv)/colorspace format)
    local net = torch.load('../data/pretrained_models/model_zeilernet.t7')
    local features = net.modules[1]
    
    -- setup classifier
    local classifier = nn.Sequential()
        :add(nn.Linear(256*6*6, 4096))
        :add(nn.ReLU(true))
        :add(nn.Dropout(0.5))
        :add(nn.Linear(4096, 4096))
        :add(nn.ReLU(true))
        :add(nn.Dropout(0.5))
    
    -- create model
    local model = nn.Sequential()
        :add(nn.ParallelTable()
            :add(utils.model.makeDataParallel(features, opt.nGPU))
            :add(nn.Identity())
        )
        :add(inn.ROIPooling(6,6,1/16))
        :add(nn.View(-1):setNumInputDims(3))
        :add(classifier)
        :add(utils.model.CreateClassifierBBoxRegressor(4096, opt.nClasses, opt.has_bbox_regressor))
    
    local model_parameters = {
        colourspace = 'rgb',
        meanstd = {mean = {0.50196078431373, 0.50196078431373, 0.50196078431373}},
        pixel_scale = 1,
        stride = 16
    }
    
    return model, model_parameters
end

return CreateModel