require 'green_shoes'
require 'mix_set'

@app = Shoes.app height: 600, width: 400, title: "MixSet Player" do

  label_size = 11
  default_margin = 8

  background rgb(240, 250, 208)

  @mix_set_player = MixSet::MixSet.new
  @filter = "all"


# Radio buttons to choose filter

  stack :margin => 10 do
     para "Choose mixes filter:"
     flow do
       radio :filter, checked: true do
        @filter = "all"
       end
       para "none",
         width: 300
     end
     flow do
       radio :filter do
        @filter = "tags"
       end
       para "tags",
         width: 300
     end
     flow do
       radio :filter do
        @filter = "keyword"
       end
       para "keywords",
         width: 300
     end
     flow do
       radio :filter do
        @filter = "artist"
       end
       para "artist name",
         width: 300
     end
   end

# Text field to enter search term

  stack :margin => 10 do
     @edit = edit_line :width => '90%'
     button 'search' do
        @text = @edit.text
        params = [@filter, @text]
        alert("#{params}")

        append do

          stack margin: default_margin do

          mixes = @mix_set_player.mixes(params)
          mixes.each_with_index do |mix, index|
            flow do
              button = button "play", tag: index
              stop_button = button "stop", tag:index
              stop_button.click do
                @mix_set_player.stop
                button.toggle()
                stop_button.toggle()
             end
              stop_button.hide()
              button.click do
                success = @mix_set_player.play [button.tag]
                button.toggle() if success
                stop_button.toggle() if success
                alert("Stream not found") unless success
             end
              para(
                mix.gsub(/&/, '&amp;'), 
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


        end
      end
    end

end