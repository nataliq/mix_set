require 'green_shoes'
require 'mix_set'

@app = Shoes.app height: 400, width: 400, title: "MixSet Player" do

  label_size = 11
  default_margin = 8

  background rgb(240, 250, 208)

  @mix_set_player = MixSet.new 
  @stack = stack margin: default_margin do

    labels = []
    @mix_set_player.list.each_with_index do |song, index| 
      puts index
      flow do
        # image "http://ficdn.audioreview.com/images/smilies/2.gif"
        button = button "play", tag: index
        button.click { @mix_set_player.play [button.tag] }
        labels << para(
          "#{song}", 
          width: 300, 
          size: label_size, 
          height: label_size, 
          margin_top: (button.height - label_size) / 2, 
          margin_left: default_margin,
          tag: index,
          stroke: red
          )
      end
    end
  end

  # @image = image "/Users/natalia.patsovska/Dropbox/Ruby/Ruby Project/lib/images/play.png", width: 23, height: 23
  # @image.click {  
  #   @image.path = "/Users/natalia.patsovska/Dropbox/Ruby/Ruby Project/lib/images/pause.png" 
  #   @image.hide
  #   @image.show
  # }
  # @b  = button "clear" do
  #      alert "button.tag = #{@b.instance_variable_get :tag}\n"
  #    end

  # def login_form
  #  para "haha"
  # end
end