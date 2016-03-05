N = 10

function class()
   local cls = {}
   cls.__index = cls

   cls.super = function()
      local o = {}
      setmetatable(o, cls)
      return o
   end
   return cls
end

-- Bandit
Bandit = class()

function Bandit.new(n)
   local o = Bandit.super()

   o.size = n
   for i=1,n do
      o[i] = { mean = torch.normal(0,1), var = 1 }
   end
   return o
end

function Bandit:sample(k)
   return torch.normal(self[k].mean, self[k].var)
end

-- Greedy learner

EpsGreedyLearner = class()

function EpsGreedyLearner.new(b, eps)
   local o = EpsGreedyLearner.super()

   o.bandit = b
   o.eps = eps
   o.values = torch.zeros(b.size)
   o.num_turns = torch.zeros(b.size)

   return o
end

function EpsGreedyLearner:experiment(n)
   local hist = torch.Tensor(n)

   local turn
   for i=1,n do
      if torch.uniform() < self.eps then
         turn = torch.random(self.bandit.size)
      else
         _, turn = torch.max(self.values,1)
         turn = turn[1]
      end

      local res = self.bandit:sample(turn)
      hist[i] = res

      self.values[turn] = (self.values[turn] * self.num_turns[turn] + res) / (self.num_turns[turn] + 1)
      self.num_turns[turn] = self.num_turns[turn] + 1
   end

   return hist
end

function EpsGreedyLearner:zero()
   for i=1,self.bandit.size do
      self.values[i] = 0
      self.num_turns[i] = 0
   end
end

function average_experiments(learner, exp_len, exp_num)
   local res = torch.Tensor(exp_num, exp_len)
   for i=1,exp_num do
      learner:zero()
      res[i] = learner:experiment(exp_len)
   end
--   print(res)
   return res:mean(1):t()
end

b = Bandit.new(10)

learner1 = EpsGreedyLearner.new(b, 0.01)
learner2 = EpsGreedyLearner.new(b, 0.1)

res1 = average_experiments(learner1, 1000, 2000)
res2 = average_experiments(learner2, 1000, 2000)

print(b)
--print(egl.num_turns)
--print(egl.values)

gp = require 'gnuplot'

gp.plot({"L1", res1, "-"}, {"L2", res2, "-"})
