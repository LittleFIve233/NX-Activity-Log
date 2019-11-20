#ifndef SCREEN_LOADING_HPP
#define SCREEN_LOADING_HPP

#include "screen.hpp"
#include <string>

namespace Screen {
    class Loading : public UI::Screen {
        private:
            // Pointer to status variable
            char * status;

        // See ui/screen.hpp for what these functions do
        public:
            Loading(bool *, char *);

            void event();

            void update(uint32_t dt);

            void draw();

            // Used to set theme
            void setTheme(bool);

            ~Loading();
    };
}

#endif