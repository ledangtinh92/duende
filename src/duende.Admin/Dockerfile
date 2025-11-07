FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG TARGETARCH
WORKDIR /src

COPY ["src/duende.Admin/duende.Admin.csproj", "src/duende.Admin/"]
COPY ["src/duende.Admin.EntityFramework.Shared/duende.Admin.EntityFramework.Shared.csproj", "src/duende.Admin.EntityFramework.Shared/"]
COPY ["src/duende.Admin.EntityFramework.SqlServer/duende.Admin.EntityFramework.SqlServer.csproj", "src/duende.Admin.EntityFramework.SqlServer/"]
COPY ["src/duende.Shared/duende.Shared.csproj", "src/duende.Shared/"]
COPY ["src/duende.Admin.EntityFramework.PostgreSQL/duende.Admin.EntityFramework.PostgreSQL.csproj", "src/duende.Admin.EntityFramework.PostgreSQL/"]
COPY ["src/duende.Admin.EntityFramework.MySql/duende.Admin.EntityFramework.MySql.csproj", "src/duende.Admin.EntityFramework.MySql/"]
RUN dotnet restore -a $TARGETARCH "src/duende.Admin/duende.Admin.csproj"
COPY . .
WORKDIR "/src/src/duende.Admin"
RUN dotnet build -a $TARGETARCH "duende.Admin.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish -a $TARGETARCH "duende.Admin.csproj" -c Release --no-restore -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENV ASPNETCORE_FORWARDEDHEADERS_ENABLED=true
ENTRYPOINT ["dotnet", "duende.Admin.dll"]