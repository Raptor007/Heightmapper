
#include <string>
#include <map>
#include <SDL/SDL.h>
#include <SDL_image/SDL_image.h>

#if defined(_ppc_) || defined(_ppc64_) || defined(__ppc__) || defined(__ppc64__) || defined(__POWERPC__) || defined(_M_PPC)
#define ENDIAN_BIG true
#else
#define ENDIAN_LITTLE true
#endif

int main( int argc, char **argv )
{
	// Check for valid command-line args.
	if( (argc < 2) || (strcmp( argv[ 1 ], "--help" ) == 0) || (strcmp( argv[ 1 ], "/?" ) == 0) )
	{
		fprintf( stderr, "Usage: %s <filename>\n", argv[ 0 ] );
		
		if( argc < 2 )
			return -1;
		return 0;
	}
	
	const char *filename = argv[ argc - 1 ];
	
	// Initialize SDL.
	if( SDL_Init( 0 ) != 0 )
	{
		fprintf( stderr, "Unable to initialize SDL: %s\n", SDL_GetError() );
		return -1;
	};
	
	// Load the image.
	SDL_Surface *surface = IMG_Load( filename );
	if( ! surface )
	{
		fprintf( stderr, "Couldn't load %s: %s\n", filename, SDL_GetError() );
		return -1;
	}
	
	// Convert the image to 32-bit RGBA in native byte order.
	#ifdef ENDIAN_BIG
		SDL_PixelFormat format = { NULL, 32, 4, 0, 0, 0, 0, 0, 8, 16, 24, 0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF, 0, 255 };
	#else
		SDL_PixelFormat format = { NULL, 32, 4, 0, 0, 0, 0, 0, 8, 16, 24, 0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000, 0, 255 };
	#endif
	SDL_Surface *temp = SDL_ConvertSurface( surface, &format, SDL_SWSURFACE );
	SDL_FreeSurface( surface );
	surface = temp;
	
	std::map< int, std::map< int, double > > heights;
	std::map< int, std::map< int, int > > indices;
	Uint8 r = 0, g = 0, b = 0, a = 0;
	int index = 0;
	
	// Read pixels into heights.
	for( int y = 0; y < surface->h; y ++ )
	{
		for( int x = 0; x < surface->w; x ++ )
		{
			index = (y * surface->w) + x;
			r = ((Uint8*)( surface->pixels ))[ index * 4 ];
			g = ((Uint8*)( surface->pixels ))[ index * 4 + 1 ];
			b = ((Uint8*)( surface->pixels ))[ index * 4 + 2 ];
			a = ((Uint8*)( surface->pixels ))[ index * 4 + 3 ];
			heights[ x ][ y ] = (r * 0.3 + g * 0.59 + b * 0.11) * a / (255. * 255.);
			indices[ x ][ y ] = index + 1;
		}
	}
	
	std::string out_filename = std::string(filename) + std::string(".obj");
	FILE *out = fopen( out_filename.c_str(), "wt" );
	if( ! out )
	{
		fprintf( stderr, "Couldn't write to: %s\n", out_filename.c_str() );
		return -1;
	}
	
	fprintf( out, "mtllib %s.mtl\n", filename );
	fprintf( out, "usemtl material\n" );
	fprintf( out, "o object\n" );
	
	double x_percent = 0., y_percent = 0.;
	int tl = 0, tr = 0, bl = 0, br = 0;
	
	// Vertices and texture coordinates.
	for( int y = 0; y < surface->h; y ++ )
	{
		for( int x = 0; x < surface->w; x ++ )
		{
			x_percent = (double)(x) / (surface->w - 1);
			y_percent = (double)(y) / (surface->h - 1);
			fprintf( out, "v %f %f %f\n", x_percent - 0.5, heights[ x ][ y ], 0.5 - y_percent );
			fprintf( out, "vt %f %f\n", x_percent, 1. - y_percent );
		}
	}
	
	// Faces.
	for( int y = 1; y < surface->h; y ++ )
	{
		for( int x = 1; x < surface->w; x ++ )
		{
			tl = indices[ x - 1 ][ y - 1 ];
			tr = indices[ x ][ y - 1 ];
			bl = indices[ x - 1 ][ y ];
			br = indices[ x ][ y ];
			fprintf( out, "f %i/%i %i/%i %i/%i\n", tl, tl, bl, bl, br, br );
			fprintf( out, "f %i/%i %i/%i %i/%i\n", tl, tl, br, br, tr, tr );
		}
	}
	
	fflush( out );
	fclose( out );
	out = NULL;
	
	return 0;
}
