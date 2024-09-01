#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

new const VERSION[] = "1.0"

public plugin_init()
{
    register_plugin("No Slow Down", VERSION, "xxx")

    RegisterHam(Ham_Player_Jump, "player", "Ham_CbasePlayer_Jump_Post", 0)
}

public Ham_CbasePlayer_Jump_Post( id )
{
    if (!is_user_bot(id) )
    {
        set_pev(id, pev_fuser2, 0.0)
    }
}