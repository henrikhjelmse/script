from PIL import Image
import pygame
# ctf extract colors : Färg - Affischproblem 2025 in SäkerhetsSM in sweden.
# image.png in the same folder :P 
#
# step 1, select colors.
# step 2, press space, then it shows only that color from the image.
def display_interactive(image):
    pygame.init()
    width, height = image.size
    box_height = 50  
    screen = pygame.display.set_mode((width, height + box_height))
    pygame.display.set_caption("ctf what the color")

    image_surface = pygame.image.frombuffer(image.tobytes(), image.size, image.mode)
    filtered_image = image_surface.copy()

    colors = []  
    selecting_colors = True  
    show_original = True

    running = True
    while running:
        screen.fill((0, 0, 0))

        if show_original:
            screen.blit(image_surface, (0, 0))
        else:
            screen.blit(filtered_image, (0, 0))

        if colors:
            box_width = width // len(colors)
            for i, color in enumerate(colors):
                pygame.draw.rect(screen, color, (i * box_width, height, box_width, box_height))

        pygame.display.flip()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
                
            elif event.type == pygame.MOUSEBUTTONDOWN and selecting_colors:
                x, y = event.pos
                if y < height:
                    pixel_color = image_surface.get_at((x, y))
                    if pixel_color not in colors:
                        colors.append(pixel_color)
                        
            elif event.type == pygame.MOUSEBUTTONDOWN and not selecting_colors:
                x, y = event.pos
                if y >= height and colors:
                    box_width = width // len(colors)
                    color_index = x // box_width
                    if color_index < len(colors):
                        selected_color = colors[color_index]
                        show_original = False
                        
                        pixel_array = pygame.PixelArray(filtered_image)
                        for px in range(width):
                            for py in range(height):
                                pixel_color = image_surface.get_at((px, py))
                                if pixel_color[:3] == selected_color[:3]:
                                    pixel_array[px, py] = selected_color
                                else:
                                    pixel_array[px, py] = (0, 0, 0)
                        del pixel_array
            
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_SPACE:
                    if selecting_colors:
                        selecting_colors = False
                        show_original = True
                    else:
                        show_original = True
                elif event.key == pygame.K_ESCAPE:
                    running = False

    pygame.quit()

def main():
    image_path = "image.png"
    
    try:
        image = Image.open(image_path)
        display_interactive(image)
    except Exception as e:
        print(f"Ett fel uppstod: {e}")

if __name__ == "__main__":
    main()