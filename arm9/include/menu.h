struct menu_item
{
	char *name;	//name of the menu
	int none;		//align for button
	char x,y,w,h;	//for button
	int type;		//type
	struct menu_unit *child;
	void (*func)(void);	//for function
};

struct menu_unit
{
	char *top;	//name of the menu
	int subcnt;		//count of items.
	void (*start)(void);	//when init the menu, call this function...
	struct menu_item *item;	//point to the submenu or the functions. maybe array.
};

struct button
{
	char *name;
	short type;
	short stat;
	char x,y,w,h;
};

extern struct button top_button[];
extern int top_bcnt;
extern struct button menu_button[];
extern int menu_bcnt;
extern struct button user_button[];
extern int user_bcnt;

extern struct button *lastbutton;
extern int lastbutton_type;
extern int lastbutton_cnt;

extern int menu_stat;
extern struct menu_unit *menu_array[16];
extern int menu_depth;
extern struct menu_unit *last_menu;
extern char last_type;
extern int menu_draw;

extern void (*menu_func)(void);

void draw_button(char *text, int x, int y, int w, int h, int color);
int add_buttonp(int group, struct button *adb);
int add_button(int group, char *name, char type, char x, char y, char w, char h);
void show_button_group(int group);
void check_button_group(int group);

void menu_hide(void);
void menu_file_loadrom(void);
void menu_file_savestate(void);
void menu_file_loadstate(void);
void menu_file_savesram(void);
void menu_file_slot(void);
void menu_file_start(void);
void menu_game_start(void);
void menu_game_pal(void);
void menu_game_ntsc(void);
void menu_game_input(void);
void menu_game_reset(void);
void menu_input_start(void);
void menu_display_start(void);
void menu_display_br(void);
void menu_display_adjust(void);
void menu_adjust_start(void);
void menu_nifi_start(void);
void menu_nifi_action(void);
void menu_extra_start(void);
void menu_extra_action(void);
void menu_cheat_search_start(void);
void menu_cheat_list_start(void);
void menu_search_action(void);
void menu_list_action(void);
void menu_cht_action(void);
void menu_debug_start(void);
void menu_debug_action(void);
void autofire_fresh(void);

void menu_shortcut_start(void);
void menu_shortcut_func(void);

void menu_config_func(void);
void menu_about_start(void);
void menu_about_action(void);
void menu_extra_fds(void);
void menu_extra_barcode(void);
void menu_saveini(void);
void menu_extra_barcode_start(void);

void show_all_pixel(void);
