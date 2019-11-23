#ifndef UI_LISTITEM_HPP
#define UI_LISTITEM_HPP

#include "drawable.hpp"
#include "SDLHelper.hpp"
#include <string>
#include "Title.hpp"

namespace UI {
    // ListItem represents an entry/item which will be stored in
    // a list. In this particular case it is specifically for presenting
    // a game's icon, name and play stats
    class ListItem : public Drawable {
        private:
            // Rendered textures for icon and strings
            SDL_Texture * icon;
            SDL_Texture * title;
            SDL_Texture * playtime;
            SDL_Texture * lastplayed;
            SDL_Texture * rank;
            // Self-explanatory
            Title * title_obj;
            bool selected;
            // Scrolling text
            int text_x;
            int text_pause;

        public:
            // See ui/screen.hpp for similar explanations of these functions
            // Assign Title pointer
            ListItem(Title *);

            void update(uint32_t);

            void draw();

            void setSelected(bool);

            void setRank(size_t);

            Title * getTitleObj();

            ~ListItem();
    };
};

#endif