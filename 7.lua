return {
  version = "1.1",
  luaversion = "5.1",
  orientation = "orthogonal",
  width = 21,
  height = 8,
  tilewidth = 128,
  tileheight = 128,
  properties = {
    ["parallax1"] = "Background_Maze_Layer1.png",
    ["parallax2"] = "Background_Maze_Layer2.png",
    ["parallax3"] = "Background_Maze_Layer3.png"
  },
  tilesets = {
    {
      name = "default",
      firstgid = 1,
      tilewidth = 128,
      tileheight = 128,
      spacing = 0,
      margin = 0,
      image = "HedgeMaze.png",
      imagewidth = 1152,
      imageheight = 640,
      properties = {},
      tiles = {
        {
          id = 15,
          properties = {
            ["solid"] = "true"
          }
        },
        {
          id = 16,
          properties = {
            ["solid"] = "true"
          }
        },
        {
          id = 31,
          properties = {
            ["solid"] = "true"
          }
        },
        {
          id = 32,
          properties = {
            ["solid"] = "true"
          }
        },
        {
          id = 35,
          properties = {
            ["solid"] = "true"
          }
        },
        {
          id = 37,
          properties = {
            ["solid"] = "true"
          }
        },
        {
          id = 38,
          properties = {
            ["solid"] = "true"
          }
        },
        {
          id = 39,
          properties = {
            ["solid"] = "true"
          }
        },
        {
          id = 40,
          properties = {
            ["solid"] = "true"
          }
        }
      }
    }
  },
  layers = {
    {
      type = "tilelayer",
      name = "Tile Layer 1",
      x = 0,
      y = 0,
      width = 21,
      height = 8,
      visible = true,
      opacity = 1,
      properties = {},
      encoding = "lua",
      data = {
        34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 0,
        34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 0,
        4, 34, 34, 34, 2, 3, 4, 34, 34, 34, 34, 34, 34, 2, 3, 4, 34, 34, 34, 2, 3,
        13, 34, 34, 34, 11, 12, 13, 34, 34, 34, 34, 34, 34, 11, 12, 13, 34, 34, 34, 11, 12,
        22, 34, 34, 34, 20, 21, 22, 34, 34, 34, 34, 34, 34, 20, 21, 22, 34, 34, 34, 20, 21,
        31, 34, 8, 34, 29, 30, 31, 34, 34, 34, 34, 34, 34, 29, 30, 31, 34, 25, 25, 29, 30,
        40, 38, 17, 38, 38, 39, 40, 34, 34, 34, 34, 34, 34, 38, 39, 40, 38, 38, 38, 38, 39,
        34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34
      }
    },
    {
      type = "objectgroup",
      name = "Object Layer 1",
      visible = true,
      opacity = 1,
      properties = {},
      objects = {
        {
          name = "",
          type = "shrinker",
          x = 896,
          y = 768,
          width = 128,
          height = 128,
          properties = {}
        },
        {
          name = "",
          type = "shrinker",
          x = 1024,
          y = 768,
          width = 128,
          height = 128,
          properties = {}
        },
        {
          name = "",
          type = "shrinker",
          x = 1152,
          y = 768,
          width = 128,
          height = 128,
          properties = {}
        },
        {
          name = "",
          type = "shrinker",
          x = 1280,
          y = 768,
          width = 128,
          height = 128,
          properties = {}
        },
        {
          name = "",
          type = "shrinker",
          x = 1408,
          y = 768,
          width = 128,
          height = 128,
          properties = {}
        },
        {
          name = "",
          type = "shrinker",
          x = 1536,
          y = 768,
          width = 128,
          height = 128,
          properties = {}
        },
        {
          name = "",
          type = "grower",
          x = 768,
          y = 640,
          width = 128,
          height = 128,
          properties = {}
        },
        {
          name = "",
          type = "player_spawn",
          x = 384,
          y = 640,
          width = 128,
          height = 128,
          properties = {}
        },
        {
          name = "",
          type = "door",
          x = 2048,
          y = 512,
          width = 256,
          height = 256,
          properties = {}
        }
      }
    }
  }
}
