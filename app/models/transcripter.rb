# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class Transcripter
  def self.from_srt(srt)
    srt.gsub("\n", '<br/>')
  end
end
